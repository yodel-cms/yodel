Yodel.config.define do |config|
  # mongo
  config.database_hostname  = 'localhost'
  config.database_port      = 27017
  config.database           = 'yodel'

  # yodel
  config.session_key        = 'yodel.session'
  config.session_secret     = 'yodel.session'
  config.sites_root         = Pathname.new('<%= sites_root.gsub("'", "\\\\'") %>')
  config.owner_user         = <%= user %>
  config.owner_group        = <%= group %>
  
  # remote
  config.remote_host        = '<%= remote_host %>'
  config.remote_name        = '<%= remote_name %>'
  config.remote_email       = '<%= remote_email %>'
  config.remote_pass        = '<%= remote_pass %>'
  
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
