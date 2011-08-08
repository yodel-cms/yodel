module Yodel
  def self.config
    @config ||= YodelConfig.new
  end
  
  def self.env
    @env ||= Environment.new
  end
  
  def self.load_extensions
    extensions = Yodel.config.root.join('extensions')
    return unless extensions.exist?
    extensions.each_entry do |extension|
      next if extension.to_s.start_with?('.')
      load_extension(extension.realpath(extensions))
    end
  end
  
  def self.load_extension(path)
    init_file     = path.join('init.rb')
    migration_dir = path.join('migrations')
    public_dir    = path.join('public')
    layouts_dir   = path.join('layouts')
    models_dir    = path.join('models')
    
    require init_file if File.exist?(init_file)
    Yodel.config.public_directories << public_dir if File.directory?(public_dir)
    Yodel.config.layout_directories << layouts_dir if File.directory?(layouts_dir)
    Yodel.config.migration_directories.insert(-2, migration_dir) if File.directory?(migration_dir)
    
    # load any models. if the init.rb file exists it will have been loaded first,
    # allowing extensions to specify the order models are loaded.
    if models_dir.exist?
      models_dir.each_entry do |model|
        next if model.to_s.start_with?('.')
        require model.realpath(models_dir)
      end
    end
  end  
end
