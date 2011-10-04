module Yodel
  MODELS_DIRECTORY_NAME               = 'models'
  PUBLIC_DIRECTORY_NAME               = 'public'
  LAYOUTS_DIRECTORY_NAME              = 'layouts'
  PARTIALS_DIRECTORY_NAME             = 'partials'
  MIGRATIONS_DIRECTORY_NAME           = 'migrations'
  ATTACHMENTS_DIRECTORY_NAME          = 'attachments'
  EXTENSION_LIB_DIRECTORY_NAME        = 'lib'
  YODEL_MIGRATIONS_DIRECTORY_NAME     = 'yodel'
  EXTENSION_MIGRATIONS_DIRECTORY_NAME = 'extensions'
  SITE_MIGRATIONS_DIRECTORY_NAME      = 'site'
  
  def self.config
    @config ||= YodelConfig.new
  end
  
  def self.env
    @env ||= Environment.new
  end
end
