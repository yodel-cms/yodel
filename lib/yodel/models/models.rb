Dir.chdir(File.dirname(__FILE__)) do
  require 'core/core'
  require 'api/api'
  require 'email/email'
  require 'pages/pages'
  require 'search/search'
  require 'security/security'
end
