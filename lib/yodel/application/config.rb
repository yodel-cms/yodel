module Yodel
  class Config
    def initialize
      @options = {
        'migration_directories' => [],
        'public_directories' => [],
        'layout_directories' => []
      }
    end
    
    def method_missing(method, *args)
      method = method.to_s
      if method[-1] == '='
        @options[method[0...-1]] = args[0]
      elsif method[-1] == '?'
        @options.has_key?(method[0...-1])
      else
        @options[method]
      end
    end
    
    def merge_defaults!
      # mongo_mapper
      self.database_hostname          ||= 'localhost'
      self.database_port              ||= 27017
      self.database                   ||= 'Yodel'
      self.db_connection              ||= Mongo::Connection.new(
                                            self.database_hostname,
                                            self.database_port
                                          ).db(self.database)
      
      # yodel
      self.session_key                ||= 'yodel.session'
      self.session_secret             ||= 'yodel.session'
      self.public_directory_name      ||= 'public'
      self.layouts_directory_name     ||= 'layouts'
      self.migrations_directory_name  ||= 'migrations'
      self.attachments_directory_name ||= 'attachments'
      
      # directories
      self.yodel_root                 ||= Pathname.new(File.dirname(__FILE__)).join('..').join('..')
      self.public_directories         << self.root.join(self.public_directory_name)
      self.layout_directories         << self.root.join(self.layouts_directory_name)
      
      # add the user migration directory to the front of the list (so it runs last)
      self.migration_directories.unshift(self.root.join(self.migrations_directory_name))
      self.migration_directories << self.yodel_root.join('yodel', 'models', 'migrations')
      
      # TODO: switch to log4r and log to a file and stdout
      # TODO: also switch rack to use this logger for requests
      # logging
      self.logger                     ||= Logger.new('yodel.log')
      self.sev_threshold              ||= Logger::DEBUG
    end
  end
end
