class Extension
  attr_reader :name, :lib_dir, :migrations_dir, :public_dir, :layouts_dir, :models_dir
  
  def initialize(gem)
    @name           = gem.name
    @lib_dir        = Pathname.new(gem.full_gem_path).join(Yodel::EXTENSION_LIB_DIRECTORY_NAME)
    @migrations_dir = lib_dir.join(Yodel::MIGRATIONS_DIRECTORY_NAME)
    @public_dir     = lib_dir.join(Yodel::PUBLIC_DIRECTORY_NAME)
    @layouts_dir    = lib_dir.join(Yodel::LAYOUTS_DIRECTORY_NAME)
    @models_dir     = lib_dir.join(Yodel::MODELS_DIRECTORY_NAME)
  end
  
  def load!
    require @name
    Yodel.config.public_directories << @public_dir if File.directory?(@public_dir)
    Yodel.config.layout_directories << @layouts_dir if File.directory?(@layouts_dir)
    Yodel.config.migration_directories << @migrations_dir if File.directory?(@migrations_dir)
    Yodel.config.extensions << self
    
    # load any models. if the init.rb file exists it will have been loaded first,
    # allowing extensions to specify the order models are loaded.
    if @models_dir.exist?
      @models_dir.each_entry do |model|
        next if model.to_s.start_with?('.')
        require model.realpath(@models_dir)
      end
    end
  end
end
