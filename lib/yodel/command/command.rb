require 'optparse'
Dir.chdir(File.dirname(__FILE__))

class CommandRunner
  def self.run
    OptionParser.new do |opts|
      opts.banner = "Usage: yodel [options] server|dns|console|migrate|setup|deploy"
      opts.on('-p', '--port PORT', Integer, 'Override the default web server port') do |port|
        $web_port = port
      end
  
      opts.on('-e', '--environment ENV', 'Web server environment (default development)', 'development', 'production') do |env|
        $env = env
      end
      
      opts.on('-s', '--settings FILE', 'Load this settings file (default: /usr/local/etc/yodel/settings.rb)') do |settings|
        $settings = settings
      end
  
      opts.on('-h', '--help', 'Display this screen') do
        puts opts
        exit
      end
    end.parse!

    command = ARGV.shift


    case command
    when 'server'
      require '../requires'
      require '../middleware/development_server'
      
      Yodel.config.web_port = $web_port if $web_port
      if $env == 'production'
        Yodel.env.production!
      else
        Yodel.env.development!
      end
      
      Rack::Server.start(app: DevelopmentServer.new, Port: Yodel.config.web_port)
  
    when 'dns'
      require '../requires'
      require './dns_server'
      DNSServer.start
  
    when 'console'
      require '../../yodel'
      require 'irb'
      $application = Application.new
      IRB.start(__FILE__)
  
    when 'migrate'
      require '../../yodel'
      $application = Application.new
      Site.all.each do |site|
        Migration.run_migrations(site)
      end
    
    when 'deploy'
      require '../../yodel'
      require './deploy'
      Deploy.new.deploy_site      
  
    when 'setup'
      require './installer'
      Installer.new.install_system_files
      
    else
      puts "Unknown command: #{command}"  
    end
  end
end
