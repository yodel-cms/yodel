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
      Gem::Specification.find_all do |gem|
        next unless gem.name.start_with?('yodel_')
        extension = GemExtension.new(gem)
        extension.load!
      end
    end
  end
end
