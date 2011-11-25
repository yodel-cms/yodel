class Extension
  attr_reader :name, :lib_dir, :migrations_dir, :public_dir, :layouts_dir, :models_dir
  
  def initialize
    @environment    = @name.end_with?('environment')
    @migrations_dir = File.join(@lib_dir, Yodel::MIGRATIONS_DIRECTORY_NAME)
    @public_dir     = File.join(@lib_dir, Yodel::PUBLIC_DIRECTORY_NAME)
    @layouts_dir    = File.join(@lib_dir, Yodel::LAYOUTS_DIRECTORY_NAME)
    @models_dir     = File.join(@lib_dir, Yodel::MODELS_DIRECTORY_NAME)
    Yodel.extensions[@name] = self
  end
  
  def load!
    unless @environment
      require_extension
      Yodel.config.public_directories << @public_dir if File.directory?(@public_dir)
      Yodel.config.layout_directories << @layouts_dir if File.directory?(@layouts_dir)
      Yodel.config.extensions << self
    end
    
    # load any models. if the init.rb file exists it will be loaded instead,
    # allowing extensions to specify the order models are loaded.
    if File.exist?(@models_dir)
      init_file = File.join(@models_dir, 'init.rb')
      if File.exist?(init_file)
        require init_file
      else
        Dir[File.join(@models_dir, '**')].sort.each do |model|
          next if model.start_with?('.')
          require File.realpath(model, @models_dir)
        end
      end
    end
  end
end

class GemExtension < Extension
  def initialize(gem)
    @name = gem.name
    @lib_dir = File.join(gem.full_gem_path, Yodel::EXTENSION_LIB_DIRECTORY_NAME)
    super()
  end
  
  def require_extension
    require @name
  end
end

class FolderExtension < Extension
  def initialize(path)
    @name = File.basename(path)
    @lib_dir = File.join(path, Yodel::EXTENSION_LIB_DIRECTORY_NAME)
    super()
  end
  
  def require_extension
    require File.join(@lib_dir, @name)
  end
end
