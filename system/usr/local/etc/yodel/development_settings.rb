Yodel.config.define do |config|
  # mongo
  config.database_hostname  = '<%= database_hostname %>'
  config.database_port      = <%= database_port %>
  config.database           = '<%= database_name %>'

  # yodel
  config.session_key        = 'yodel.session'
  config.session_secret     = 'yodel.session'
  config.sites_root         = '<%= sites_root %>'
  config.owner_user         = <%= user %>
  config.owner_group        = <%= group %>
  
  # environment
  config.web_port           = <%= web_port %>
  config.dns_port           = <%= dns_port %>
  config.git_path           = '<%= git_path %>'
  config.identify_path      = '<%= identify_path %>'
  config.convert_path       = '<%= convert_path %>'

  # logging
  config.logger             = Logger.new('/var/log/yodel.log')
  config.sev_threshold      = Logger::INFO
end

Yodel.env.development!

Mail.defaults do
  delivery_method :sendmail
end
