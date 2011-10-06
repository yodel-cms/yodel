module Yodel
  def self.db
    @db ||= Mongo::Connection.new(Yodel.config.database_hostname, Yodel.config.database_port).db(Yodel.config.database)
  end
  
  def self.load_extensions
    Gem::Specification.find_all do |gem|
      next unless gem.name.start_with?('yodel_') && !gem.name.end_with?('environment')
      extension = Extension.new(gem)
      extension.load!
    end
  end
end
