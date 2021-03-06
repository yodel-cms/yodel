class Layout < Record
  MAX_LOCK_ATTEMPTS = 1000 # FIXME: is this appropriate? how long does each attempt take?
  
  # in development, all layout records are destroyed and recreated each
  # refresh, so the database view of the layout structure is consistent
  # with what is on disk. FileLayout objects lazy load the layout from
  # disk as needed. In production, PersistentLayout records store the
  # layout markup in the database.
  def self.reload_layouts(site)
    # acquire a lock on the site to prevent multiple reloads colliding
    attempts = 0
    updated = 0

    # sites created in production that are yet to be pushed to won't have
    # any models (including layouts) or any layouts to load
    return if site.model_types['layouts'].nil?
    
    while updated == 0 && attempts < MAX_LOCK_ATTEMPTS
      updated = Site.collection.update(
        {'_id' => site.id, 'layout_lock' => {'$exists' => false}},
        {'$set' => {'layout_lock' => true}},
        safe: true)['n']
      attempts += 1
    end
    
    raise UnableToAcquireLock if attempts == MAX_LOCK_ATTEMPTS
      
    # lock has been acquired, this section is guarded
    site.layouts.all.each(&:destroy)
    Yodel.mime_types.each do |mime_type|
      mime_type_name = mime_type.name.to_s
      mime_type_extensions = mime_type.extensions.join(',')
      site.layout_directories.each do |directory|
        scan_folder(directory, site, mime_type_name, mime_type_extensions, nil)
      end
    end

  # release the lock
  ensure
    if attempts != 0
      updated = Site.collection.update(
        {'_id' => site.id, 'layout_lock' => {'$exists' => true}},
        {'$unset' => {'layout_lock' => 1}},
        safe: true)['n']
      raise InconsistentLockState if updated != 1
    end
  end

  def render(page)
    method = "render_#{Yodel.mime_types[mime_type.to_sym].layout_processor}"
    if respond_to?(method)
      send(method, page)
    else
      render_default(page)
    end
  end
  
  def self.render(name, &block)
    define_method("render_#{name}", block)
  end
  
  render :default do |page|
    markup
  end
  
  
  private
    def self.scan_folder(path, site, mime_type_name, mime_type_extensions, parent)
      return unless File.directory?(path)
      
      # create layouts for all mime type files, then scan for any
      # sub-layouts in folders with the same name as the layout
      Dir.glob(File.join(path, "*.{#{mime_type_extensions}}")).each do |file_path|
        name = File.basename(file_path, File.extname(file_path))
        if site.layouts.exists?(name: name, mime_type: mime_type_name)
          other_layout = site.layouts.where(name: name, mime_type: mime_type_name).first
          raise DuplicateLayout, file_path, other_layout.path
        end
        
        layout = site.file_layouts.new
        layout.name = name
        layout.parent = parent
        layout.path = file_path
        layout.mime_type = mime_type_name
        layout.save
      
        # scan for sub layouts
        sub_layouts_folder = File.join(File.dirname(file_path), name)
        scan_folder(sub_layouts_folder, site, mime_type_name, mime_type_extensions, layout)
      end
    end
end


class PersistentLayout < Layout
  # markup is defined as a field of persistent layouts
  def options
    {}
  end
end

class FileLayout < Layout
  def markup
    IO.read(path)
  end
  
  def options
    {source_file: path}
  end
  
  render :ember do |page|
    page.set_content(Ember::Template.new(markup, options).render(page.get_binding))
    parent.render(page) if parent
    page.content
  end
  
  render :eval do |page|
    page.instance_eval(markup)
  end
end
