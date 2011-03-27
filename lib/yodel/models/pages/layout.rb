module Yodel
  class Layout < Record
    def self.reload_mutex
      @reload_mutex ||= Mutex.new
    end
    
    # in development, all layout records are destroyed and recreated each
    # refresh, so the database view of the layout structure is consistent
    # with what is on disk. FileLayout objects lazy load the layout from
    # disk as needed. In production, PersistentLayout records store the
    # layout markup in the database.
    def self.reload_layouts(site)
      reload_mutex.synchronize do
        site.layouts.all.each(&:destroy)
        Yodel.config.layout_directories.each {|directory| scan_folder(directory, site, nil)}
      end
    end

    def render(page)
      page.set_content(Erubis::Eruby.new(markup).evaluate(page))
      parent.render(page) if parent
      page.content
    end
    
    private
      def self.scan_folder(path, site, parent)
        return unless File.directory?(path)
        
        # create layouts for all html files, then scan for any
        # sub-layouts in folders with the same name as the layout
        Dir.glob(File.join(path, '*.html')).each do |file_path|
          name = File.basename(file_path, '.html')
          raise Yodel::DuplicateLayout if site.layouts.exists?(name: name)
          
          layout = site.file_layouts.new
          layout.name = name
          layout.parent = parent
          layout.path = file_path
          layout.save
          
          # scan for sub layouts
          scan_folder(file_path[0...-5], site, layout)
        end
      end
  end
  
  class PersistentLayout < Layout
  end
  
  class FileLayout < Layout
    def markup
      IO.read(path)
    end
  end
end
