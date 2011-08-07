module Yodel
  def self.config
    @config ||= YodelConfig.new
  end
  
  def self.env
    @env ||= Environment.new
  end
  
  def self.load_extensions
    Impromptu.components.each do |component|
      next unless component.name.start_with?('yodel.extensions.')
      load_extension(component.folders.first)
    end
  end
  
  def self.load_extension(models_folder)
    path          = models_folder.folder.join('..')
    init_file     = path.join('init.rb')
    migration_dir = path.join('migrations')
    public_dir    = path.join('public')
    layouts_dir   = path.join('layouts')
    
    require init_file if File.exist?(init_file)
    Yodel.config.public_directories << public_dir if File.directory?(public_dir)
    Yodel.config.layout_directories << layouts_dir if File.directory?(layouts_dir)
    Yodel.config.migration_directories.insert(-2, migration_dir) if File.directory?(migration_dir)
    models_folder.preload!
  end
  
  def self.use_middleware(&block)
    @extension_middleware ||= []
    @extension_middleware << block
  end
  
  def self.initialise_middleware_with_app(app)
    @extension_middleware ||= []
    @extension_middleware.each do |middleware_declaration|
      middleware_declaration.call(app)
    end
  end  
end
