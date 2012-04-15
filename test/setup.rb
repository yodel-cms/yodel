require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

class Test::Unit::TestCase
end


# boot yodel - set the extensions folder with "EXT=path"
# e.g rake EXT=/path/to/extensions test
require 'yodel'
extensions_folder = ENV['EXT']
Yodel.config.extensions_folder = extensions_folder if extensions_folder
Yodel.load_extensions


# set up the test site. This assumes yodel has been installed and
# set up successfully.
TestUser = Struct.new('User', :name, :email, :password)
$default_user = TestUser.new('Test User', 'test@test.com', 'n/a')
$test_site = Site.create('test', $default_user)

# copy the test site's model migrations
FileUtils.remove_entry_secure($test_site.site_migrations_directory)
FileUtils.cp_r(File.join(File.dirname(__FILE__), 'migrations'), $test_site.site_migrations_directory)
Migration.run_migrations($test_site)
