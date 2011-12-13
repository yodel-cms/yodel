module Yodel
  def self.db
    @db ||= Mongo::Connection.new(Yodel.config.database_hostname, Yodel.config.database_port).db(Yodel.config.database)
  end
  
  def self.extensions
    @extensions ||= {}
  end
  
  def self.load_extensions
    if Yodel.config.extensions_folder
      Dir[File.join(Yodel.config.extensions_folder, '/*')].each do |path|
        next unless File.directory?(path) && File.basename(path).start_with?('yodel_')
        extension = FolderExtension.new(path)
        extension.load!
      end
    else
      # find the latest version of each yodel extension
      latest_gem_version = {}
      Gem::Specification.find_all do |gem|
        next unless gem.name.start_with?('yodel_')
        if !latest_gem_version.key?(gem.name) || gem.version > latest_gem_version[gem.name].version
          latest_gem_version[gem.name] = gem
        end
      end
      
      # only load the latest versions
      latest_gem_version.each_value do |gem|
        extension = GemExtension.new(gem)
        extension.load!
      end
    end
  end
end
