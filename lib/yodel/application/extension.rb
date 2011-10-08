class Extension
  attr_reader :name, :lib_dir, :migrations_dir, :public_dir, :layouts_dir, :models_dir
  
  def initialize(gem, environment=false)
    @name           = gem.name
    @environment    = environment
    @lib_dir        = File.join(gem.full_gem_path, Yodel::EXTENSION_LIB_DIRECTORY_NAME)
    @migrations_dir = File.join(@lib_dir, Yodel::MIGRATIONS_DIRECTORY_NAME)
    @public_dir     = File.join(@lib_dir, Yodel::PUBLIC_DIRECTORY_NAME)
    @layouts_dir    = File.join(@lib_dir, Yodel::LAYOUTS_DIRECTORY_NAME)
    @models_dir     = File.join(@lib_dir, Yodel::MODELS_DIRECTORY_NAME)
  end
  
  def load!
    unless @environment
      require @name
      Yodel.config.public_directories << @public_dir if File.directory?(@public_dir)
      Yodel.config.layout_directories << @layouts_dir if File.directory?(@layouts_dir)
      Yodel.config.extensions << self
    end
    
    # load any models. if the init.rb file exists it will have been loaded first,
    # allowing extensions to specify the order models are loaded.
    if File.exist?(@models_dir)
      Dir.foreach(@models_dir) do |model|
        next if model.start_with?('.')
        require File.realpath(model, @models_dir)
      end
    end
  end
end