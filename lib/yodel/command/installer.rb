require 'fileutils'
require 'highline'
require 'tempfile'
require 'digest'
require 'ember'
require '../models/security/password'

class Installer
  # ----------------------------------------
  # Template variables
  # ----------------------------------------
  attr_reader :sites_root, :web_port, :dns_port, :remote_name, :remote_host, :remote_email, :remote_pass, :user, :group
  
  def default_sites_root
    if `uname -a` =~ /Darwin/
      File.expand_path('~/Sites')
    else
      '/var/www'
    end
  end
  
  def ruby_path
    unless @ruby_path
      if Config.ruby =~ /rubies\/(.*)\/bin/
        `rvm wrapper #{$1} yodel`
        @ruby_path = `which yodel_ruby`.strip
      else
        @ruby_path = Config.ruby
      end
    end
    @ruby_path
  end
  
  
  # ----------------------------------------
  # Helpers
  # ----------------------------------------
  def system_path
    @system_path ||= File.join(File.dirname(__FILE__), '..', '..', '..', 'system')
  end
  
  def report(verb, noun)
    @h.say "<%= color('#{verb}', GREEN) %>\t#{noun}"
  end
  
  def escape_quotes(str)
    str.gsub("'", "\\\\'")
  end
  
  def install(file, permissions='0644')
    dest_path   = File.join('/', file)
    source_path = File.join(system_path, file)
    temp_file   = Tempfile.new('yodel')
    report('installing', dest_path)
    
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
    
    # local sites directory
    h.say "<%= color('1/5', RED) %> <%= color('Sites Directory', BOLD) %>"
    h.say "Yodel stores each of your sites in a single directory. You may place this directory"
    h.say "anywhere, but all sites created by Yodel must be accessible from it. Press enter to"
    h.say "accept the default directory, or enter a new path."
    @sites_root = h.ask("Sites directory: ") do |q|
      q.default = default_sites_root
      q.responses[:ask_on_error] = :question
    end
    
    # web server port
    h.say "\n<%= color('2/5', RED) %> <%= color('Local Server', BOLD) %>"
    h.say "By default the yodel server will run on port 80, meaning you can access yodel"
    h.say "sites by visiting <http://sitename.yodel/>. If you already have Apache or"
    h.say "another web server running on this port, enter a different port (such as 8080)"
    @web_port = h.ask("Use port: ", Integer) do |q|
      q.default = 80
      q.responses[:ask_on_error] = :question
    end
    @dns_port = 2827
    
    # remote host
    h.say "\n<%= color('3/5', RED) %> <%= color('Remote Host', BOLD) %>"
    h.say "Yodel allows you to sync your sites with a remote host. By default this will"
    h.say "be with <http://yodelcms.com/>. If you use a different host, enter it here."
    @remote_host = h.ask("Remote host: ") do |q|
      q.default = "yodelcms.com"
      q.responses[:ask_on_error] = :question
    end
    
    # remote login
    h.say "\n<%= color('4/5', RED) %> <%= color('Remote Login', BOLD) %>"
    h.say "Enter your name, email and password for this host. Your password will be"
    h.say "encrypted on disk, and when sent to the server."
    @remote_name = h.ask("Name: ") do |q|
      q.validate = /.+/
      q.default = `whoami`.strip
      q.responses[:not_valid] = "Your name is required"
      q.responses[:ask_on_error] = :question
    end
    @remote_email = h.ask("Email: ") do |q|
      q.validate = /.+/
      q.responses[:not_valid] = "Your email is required"
      q.responses[:ask_on_error] = :question
    end
    @remote_pass = h.ask("Password: ") do |q|
      q.echo = false
      q.validate = /.+/
      q.responses[:not_valid] = "Your password is required"
      q.responses[:ask_on_error] = :question
    end
    @remote_pass = Password.hashed_password(nil, @remote_pass)
    
    # automatically detect the user's current username and group
    `touch /tmp/group_test`
    @user  = File.stat("/tmp/group_test").uid
    @group = File.stat("/tmp/group_test").gid
    `rm /tmp/group_test`
    
    h.say "\n<%= color('5/5', RED) %> <%= color('Installation', BOLD) %>"
    h.say "Yodel will now install the necessary system files. You may be asked to enter"
    h.say "your local user password.\n\n"
    h.say "-----------------------------------------------------------------------------\n\n"
    
    if `uname -a` =~ /Darwin/
      install_mac_files
    else
      install_linux_files
    end
    
    h.say "\n-----------------------------------------------------------------------------"
    h.say "\n<%= color('Installation complete', BOLD) %>"
    h.say "Visit http://yodel#{":#{@web_port}" if @web_port != 80}/ to clone any existing sites from http://#{@remote_host}/"
    h.say "You can create a new site by visiting <http://sitename.yodel#{":#{@web_port}" if @web_port != 80}/> and following"
    h.say "the instructions\n\n"
  end
  
  
  # ----------------------------------------
  # OS X
  # ----------------------------------------
  def install_mac_files
    install 'etc/resolver/yodel'
    install 'Library/LaunchDaemons/com.yodelcms.dns.plist'
    install 'Library/LaunchDaemons/com.yodelcms.server.plist'
    install 'usr/local/bin/yodel_command_runner', '0777'
    install 'usr/local/etc/yodel/settings.rb'
    install 'var/log/yodel.log', '0666'
    
    report('starting', 'dns server')
    if `sudo launchctl list` =~ /\d+.+com.yodelcms.dns$/
      `sudo launchctl unload /Library/LaunchDaemons/com.yodelcms.dns.plist`
    end
    `sudo launchctl load /Library/LaunchDaemons/com.yodelcms.dns.plist`
    
    report('starting', 'web server')
    if `sudo launchctl list` =~ /\d+.+com.yodelcms.server$/
      `sudo launchctl unload /Library/LaunchDaemons/com.yodelcms.server.plist`
    end
    `sudo launchctl load /Library/LaunchDaemons/com.yodelcms.server.plist`
  end
  
  
  # ----------------------------------------
  # Linux
  # ----------------------------------------
  def install_linux_files
    install 'usr/local/bin/yodel_command_runner', '0777'
    install 'usr/local/etc/yodel/settings.rb'
    install 'var/log/yodel.log', '0666'
  end
end
