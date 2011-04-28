module Yodel
  class LogEntry < SiteRecord
    DEBUG = 0
    INFO  = 1
    WARN  = 2
    ERROR = 3
    FATAL = 4
    
    collection :log
    field :severity, :integer, default: INFO
    field :created_at, :time
    field :message, :string    
  end
end
