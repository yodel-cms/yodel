module Yodel
  class Log
    def initialize(site)
      @site = site
    end
    
    def debug(message)
      build_log_entry(Yodel::LogEntry::DEBUG, message)
    end
    
    def info(message)
      build_log_entry(Yodel::LogEntry::INFO, message)
    end
    
    def warn(message)
      build_log_entry(Yodel::LogEntry::WARN, message)
    end
    
    def error(message)
      build_log_entry(Yodel::LogEntry::ERROR, message)
    end
    
    def fatal(message)
      build_log_entry(Yodel::LogEntry::FATAL, message)
    end
    
    private
      def build_log_entry(severity, message)
        entry = Yodel::LogEntry.new(@site)
        entry.update(severity: severity, message: message)
      end
  end
end
