require 'logger'

Yodel.config.define do |config|
  # mongo
  config.database_hostname  = 'localhost'
  config.database_port      = 27017
  config.database           = 'Yodel'

  # yodel
  config.session_key        = 'yodel.session'
  config.session_secret     = 'yodel.session'
  config.sites_root         = "<%= sites_root %>"
  
  # servers
  config.web_port           = <%= web_port %>
  config.dns_port           = <%= dns_port %>

  # TODO: switch to log4r and log to a file and stdout
  # TODO: also switch rack to use this logger for requests
  # logging
  config.logger             = Logger.new('/var/log/yodel.log')
  config.sev_threshold      = Logger::INFO
end

Mail.defaults do
  delivery_method :sendmail
end
