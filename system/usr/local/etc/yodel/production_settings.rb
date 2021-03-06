Yodel.config.define do |config|
  # mongo
  config.database_hostname  = '<%= database_hostname %>'
  config.database_port      = <%= database_port %>
  config.database           = '<%= database_name %>'

  # yodel
  config.session_key        = 'yodel.session'
  config.session_secret     = 'yodel.session'
  config.sites_root         = '<%= sites_root %>'
  
  # environment
  config.dns_port           = <%= dns_port %>
  config.public_directory   = '<%= public_directory %>'
  config.deploy_command     = 'yodel'
  config.git_path           = '<%= git_path %>'
  config.identify_path      = '<%= identify_path %>'
  config.convert_path       = '<%= convert_path %>'

  # logging
  config.logger             = Logger.new('/var/log/yodel.log')
  config.sev_threshold      = Logger::INFO
end

Yodel.env.production!

Mail.defaults do
  delivery_method :sendmail
end
