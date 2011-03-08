module Yodel
  class Config
    def initialize
      @options = {
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
      
      # yodel
      self.session_key                ||= 'yodel.session'
      self.session_secret             ||= 'yodel.session'
      self.public_directory_name      ||= 'public'
      self.layout_directory_name      ||= 'layouts'
      self.attachment_directory_name  ||= 'attachments'
      
      # directories
      self.yodel_root                 ||= Pathname.new(File.dirname(__FILE__)).join('..').join('..')
      self.public_directories         << self.root.join(self.public_directory_name)
      self.layout_directories         << self.root.join(self.layout_directory_name)
      
      # logging
      self.logger                     ||= Logger.new('yodel.log')
      self.sev_threshold              ||= Logger::DEBUG
    end
  end
end
