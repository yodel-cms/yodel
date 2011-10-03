require 'fileutils'
require 'tempfile'
require 'ember'

class Installer
  def self.system_path
    @system_path ||= File.join(File.dirname(__FILE__), '..', '..', '..', 'system')
  end
  
  def self.install_system_files
    puts "Installing yodel system files\n"
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
    install 'usr/local/bin/yodel', '0744'
    install 'usr/local/etc/yodel/settings.rb'
    install 'var/log/yodel.log', '0666'
    
    puts 'starting yodel dns server...'
    `sudo launchctl unload /Library/LaunchDaemons/com.yodelcms.dns.plist`
    `sudo launchctl load /Library/LaunchDaemons/com.yodelcms.dns.plist`
    puts 'starting yodel web server...'
  end
  
  def self.install_linux_files
    install 'usr/local/bin/yodel', '0744'
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
      File.expand_path("~/Sites")
    else
      "/var/www"
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
end
