require './feedback'
require './restart'
require 'tempfile'
require 'ember'
require 'etc'

class Installer
  # ----------------------------------------
  # Template variables
  # ----------------------------------------
  attr_reader :database_hostname, :database_port, :database_name,
              :sites_root, :ruby_path, :web_port, :dns_port,
              :user, :group, :public_directory, :git_path,
              :identify_path, :convert_path
  
  def default_sites_root
    if `uname -a` =~ /Darwin/
      File.expand_path('~/Sites')
    else
      '/var/www'
    end
  end
  
  def default_ruby_path
    if RbConfig.ruby =~ /rubies\/(.*)\/bin/
      `rvm wrapper #{$1} yodel`
      `which yodel_ruby`.strip
    else
      Config.ruby
    end
  end
  
  def assign_default_user_and_group
    pwnam   = Etc.getpwnam(Etc.getlogin)
    @user   = pwnam.uid
    @group  = pwnam.gid
  end
  
  def initialize
    # assign default values; not all values have associated questions
    # presented to the user depen
    @database_hostname  = 'localhost'
    @database_port      = 27017
    @database_name      = 'yodel'
    @web_port           = 80
    @dns_port           = 2828
    @public_directory   = '/var/www'
    @sites_root         = default_sites_root
    @ruby_path          = default_ruby_path
    @git_path           = `which git`.strip
    @identify_path      = `which identify`.strip
    @convert_path       = `which convert`.strip
    assign_default_user_and_group
  end
  
  
  # ----------------------------------------
  # Helpers
  # ----------------------------------------
  def system_path
    @system_path ||= File.join(File.dirname(__FILE__), '..', '..', '..', 'system')
  end
  
  def escape_quotes(str)
    str.gsub("'", "\\\\'")
  end
  
  def install(file, permissions='0644', file_name=nil)
    if file_name
      dest_path = File.join('/', File.dirname(file), file_name)
    else
      dest_path = File.join('/', file)
    end
    source_path = File.join(system_path, file)
    temp_file   = Tempfile.new('yodel')
    Feedback.report('installing', dest_path)
    
    # render the file template
    temp_file.write Ember::Template.new(IO.read(source_path), {source_file: source_path}).render(binding)
    temp_file.close
    
    # create parent directories, copy the rendered file and set permissions
    `sudo mkdir -p #{File.dirname(dest_path)}`
    `sudo cp #{temp_file.path} #{dest_path}`
    `sudo chmod #{permissions} #{dest_path}`
    
    # delete the temp file used for rendering
    temp_file.unlink
  end
  
  
  # ----------------------------------------
  # Q & A
  # ----------------------------------------
  def install_system_files
    @h = h = HighLine.new
    h.say "\n<%= color('Welcome to Yodel', BOLD) %>\n\n"
    
    # environment
    h.say "<%= color('Environment', BOLD) %>"
    h.say "Yodel can run in development (local) mode or as a production server. Press"
    h.say "enter to setup Yodel in development mode, or enter 'production' to setup"
    h.say "a production server."
    @environment = h.ask("Environment: ") do |q|
      q.default = 'development'
      q.in = %w{development production}
      q.responses[:ask_on_error] = :question
    end
    
    # local sites directory
    h.say "\n<%= color('1/3', RED) %> <%= color('Sites Directory', BOLD) %>"
    h.say "Yodel stores each of your sites in a single directory. You may place this directory"
    h.say "anywhere, but all sites created by Yodel must be accessible from it. Press enter to"
    h.say "accept the default directory, or enter a new path."
    @sites_root = h.ask("Sites directory: ") do |q|
      q.default = @sites_root
      q.responses[:ask_on_error] = :question
    end
    @sites_root = escape_quotes(@sites_root)
    
    # web server port
    if @environment == 'development'
      h.say "\n<%= color('2/3', RED) %> <%= color('Local Server', BOLD) %>"
      h.say "By default the yodel server will run on port 80, meaning you can access yodel"
      h.say "sites by visiting <http://sitename.yodel/>. If you already have Apache or"
      h.say "another web server running on this port, enter a different port (such as 8080)"
      @web_port = h.ask("Use port: ", Integer) do |q|
        q.default = @web_port
        q.responses[:ask_on_error] = :question
      end
    else
      h.say "\n<%= color('2/3', RED) %> <%= color('Public Directory', BOLD) %>"
      h.say "Yodel symlinks the public directory of sites served by the production server"
      h.say "to a directory visible to the fronting web server. The domain of a site is"
      h.say "used as the link name, meaning /var/www/domain.com could e.g link to"
      h.say "/var/git/ID/public. This makes serving public assets from a fronting server"
      h.say "possible by rewriting the request path to include the domain of the request."
      @public_directory = h.ask("Public directory: ") do |q|
        q.default = @public_directory
        q.responses[:ask_on_error] = :question
      end
      @public_directory = escape_quotes(@public_directory)
    end
    
    h.say "\n<%= color('3/3', RED) %> <%= color('Installing files', BOLD) %>"
    h.say "Yodel will now install the necessary system files. You may be asked to enter"
    h.say "your local user password.\n\n"
    h.say "-----------------------------------------------------------------------------\n\n"
    
    # default program paths
    Feedback.report('locating', "git: #{@git_path}")
    Feedback.report('warning', "git not found, path must be set manually in /usr/local/etc/yodel/settings.rb") if @git_path.empty?
    Feedback.report('locating', "identify: #{@identify_path}")
    Feedback.report('warning', "identify not found, path must be set manually in /usr/local/etc/yodel/settings.rb") if @identify_path.empty?
    Feedback.report('locating', "convert: #{@convert_path}")
    Feedback.report('warning', "convert not found, path must be set manually in /usr/local/etc/yodel/settings.rb") if @convert_path.empty?
    
    # install system files
    if `uname -a` =~ /Darwin/
      install_mac_files
    else
      install_linux_files
    end
    
    # start yodel for environment installation
    Feedback.report('starting', 'yodel')
    require '../../yodel'
    Yodel.config.extensions_folder = $extensions_folder if $extensions_folder
    Yodel.load_extensions
    
    # install an environment support site
    Feedback.report('installing', "#{@environment} environment support site")
    site = Site.new
    site.name = "yodel"
    site.domains = ['yodel', 'localhost', '127.0.0.1']
    extension = Yodel.extensions["yodel_#{@environment}_environment"]
    puts "Installation environment (#{@environment}) not found" and exit(1) if extension.nil?
    site.root_directory = extension.lib_dir
    site.save
    Migration.run_migrations(site)
    
    h.say "\n-----------------------------------------------------------------------------"
    h.say "\n<%= color('Installation complete', BOLD) %>"
    h.say "Visit http://yodel#{":#{@web_port}" if @web_port != 80}/ to setup accounts you have on a remote Yodel server."
    h.say "You can create a new site by visiting <http://sitename.yodel#{":#{@web_port}" if @web_port != 80}/> and"
    h.say "following the instructions\n\n"
  end
  
  
  # ----------------------------------------
  # OS X
  # ----------------------------------------
  def install_mac_files
    install 'etc/resolver/yodel'
    install 'Library/LaunchDaemons/com.yodelcms.dns.plist'
    install 'Library/LaunchDaemons/com.yodelcms.server.plist'
    install 'usr/local/bin/yodel_command_runner', '0777'
    install 'var/log/yodel.log', '0666'
    
    case @environment
    when 'development'
      install 'usr/local/etc/yodel/development_settings.rb', '0644', 'settings.rb'
    when 'production'
      install 'usr/local/etc/yodel/production_settings.rb', '0644', 'settings.rb'
    end
    
    Restart.restart!
  end
  
  
  # ----------------------------------------
  # Linux
  # ----------------------------------------
  def install_linux_files
    install 'usr/local/bin/yodel_command_runner', '0777'
    install 'var/log/yodel.log', '0666'
    
    case @environment
    when 'development'
      install 'usr/local/etc/yodel/development_settings.rb', '0644', 'settings.rb'
    when 'production'
      install 'usr/local/etc/yodel/production_settings.rb', '0644', 'settings.rb'
    end
  end
end
