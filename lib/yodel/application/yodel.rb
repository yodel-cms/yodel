module Yodel
  def self.db
    @db ||= Mongo::Connection.new(Yodel.config.database_hostname, Yodel.config.database_port).db(Yodel.config.database)
  end
  
  def self.load_extensions
    Gem::Specification.find_all do |gem|
      load_extension(gem) if gem.name =~ /yodel_/
    end
  end
  
  def self.load_extension(extension)
    require extension.name
    lib_dir         = Pathname.new(extension.full_gem_path).join(EXTENSION_LIB_DIRECTORY_NAME)
    migrations_dir  = lib_dir.join(MIGRATIONS_DIRECTORY_NAME)
    public_dir      = lib_dir.join(PUBLIC_DIRECTORY_NAME)
    layouts_dir     = lib_dir.join(LAYOUTS_DIRECTORY_NAME)
    models_dir      = lib_dir.join(MODELS_DIRECTORY_NAME)
    
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
