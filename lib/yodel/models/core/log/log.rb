require './log/log_entry'

class Log
  def initialize(site)
    @site = site
  end
  
  def debug(message)
    build_log_entry(LogEntry::DEBUG, message)
  end
  
  def info(message)
    build_log_entry(LogEntry::INFO, message)
  end
  
  def warn(message)
    build_log_entry(LogEntry::WARN, message)
  end
  
  def error(message)
    build_log_entry(LogEntry::ERROR, message)
  end
  
  def fatal(message)
    build_log_entry(LogEntry::FATAL, message)
  end
  
  private
    def build_log_entry(severity, message)
      entry = LogEntry.new(@site)
      entry.update(severity: severity, message: message)
    end
end
