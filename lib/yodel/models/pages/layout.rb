module Yodel
  class Layout < Yodel::Model
    key :name, String, required: true, index: true # FIXME: needs to be unique for a site    
    
    # in development, all layout records are destroyed and recreated each
    # refresh, so the database view of the layout structure is consistent
    # with what is on disk. FileLayout objects lazy load the layout from
    # disk as needed. In production, PersistentLayout records store the
    # layout markup in the database.
    def self.reload_layouts(site)
      self.all_for(site).each(&:destroy)
      Yodel.config.layout_directories.each {|directory| scan_folder(directory, site, nil)}
    end

    def render_with_context(context)
      context.set_value('content', Erubis::Eruby.new(markup).evaluate(context))
      parent.render_with_context(context) if parent
      context.get_value('content')
    end
    
    private
      def self.scan_folder(path, site, parent)
        return unless File.directory?(path)
        
        # create layouts for all html files, then scan for any
        # sub-layouts in folders with the same name as the layout
        Dir.glob(File.join(path, '*.html')).each do |file_path|
          # find or create the layout
          name = File.basename(file_path, '.html')
          if self.all_for(site).exists?(name: name)
            layout = self.all_for(site).where(name: name).first
            Yodel.logger.warn("Overriding existing layout #{name} with file: #{file_path}")
          else
            layout = FileLayout.new
            layout.name = name
            layout.site = site
          end
          layout.parent = parent
          layout.path = file_path
          layout.save
          
          # scan for sub layouts
          scan_folder(file_path[0...-5], site, layout)
        end
      end
  end
  
  class PersistentLayout < Layout
    key :markup, ::HTMLCode, required: true
    searchable false
  end
  
  class FileLayout < Layout
    key :path, String, required: true
    searchable false
    
    def markup
      IO.read(path)
    end
  end
end
