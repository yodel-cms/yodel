require 'fileutils'
require 'tempfile'
require 'ember'

class Installer
  def self.system_path
    @system_path ||= File.join(File.dirname(__FILE__), '..', '..', '..', 'system')
  end
  
  def self.install_system_files
    puts "Installing yodel system files...\n"
    puts 'By default, the yodel server will run on port 80, meaning you can access yodel'
    puts 'sites by visiting <http://sitename.yodel/>. If you already have Apache or'
    puts 'another web server running on this port, enter a different port (such as 8080)'
    puts 'Press enter to use port 80 by default.'
    print 'Use port [80]:'
    @web_port = gets.strip.to_i
    @web_port = 80 unless @web_port > 0
    
    if `uname -a` =~ /Darwin/
      install_mac_files
    else
      install_linux_files
    end
    puts "\nInstallation complete"
  end
  
  def self.install_mac_files
    install 'etc/resolver/yodel'
    install 'Library/LaunchDaemons/com.yodelcms.dns.plist'
    install 'Library/LaunchDaemons/com.yodelcms.server.plist'
    install 'usr/local/bin/yodel_command_runner', '0777'
    install 'usr/local/etc/yodel/settings.rb'
    install 'var/log/yodel.log', '0666'
    
    puts 'starting yodel dns server...'
    if `sudo launchctl list` =~ /\d+.+com.yodelcms.dns$/
      `sudo launchctl unload /Library/LaunchDaemons/com.yodelcms.dns.plist`
    end
    `sudo launchctl load /Library/LaunchDaemons/com.yodelcms.dns.plist`
    
    puts 'starting yodel web server...'
    if `sudo launchctl list` =~ /\d+.+com.yodelcms.server$/
      `sudo launchctl unload /Library/LaunchDaemons/com.yodelcms.server.plist`
    end
    `sudo launchctl load /Library/LaunchDaemons/com.yodelcms.server.plist`
  end
  
  def self.install_linux_files
    install 'usr/local/bin/yodel_command_runner', '0777'
    install 'usr/local/etc/yodel/settings.rb'
    install 'var/log/yodel.log', '0666'
  end
  
  def self.install(file, permissions='0644')
    dest_path   = File.join('/', file)
    source_path = File.join(system_path, file)
    temp_file   = Tempfile.new('yodel')
    puts "installing: #{dest_path}"
    
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
  
  # template variables
  def self.sites_root
    if `uname -a` =~ /Darwin/
      File.expand_path('~/Sites')
    else
      '/var/www'
    end
  end
  
  def self.ruby_path
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
  
  def self.web_port
    @web_port
  end
  
  def self.dns_port
    2827
  end
end
