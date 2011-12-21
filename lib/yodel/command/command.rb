require 'optparse'
Dir.chdir(File.dirname(__FILE__))
Encoding.default_external = "utf-8"

class CommandRunner
  def self.run
    OptionParser.new do |opts|
      opts.banner = "Usage: yodel [options] server|dns|restart|console|migrate|deploy|setup|update"
      opts.on('-p', '--port PORT', Integer, 'Override the default web server port') do |port|
        $web_port = port
      end
  
      opts.on('-e', '--environment ENV', 'Web server environment (default development)', 'development', 'production') do |env|
        $env = env
      end
      
      opts.on('-s', '--settings FILE', 'Load this settings file (default: /usr/local/etc/yodel/settings.rb)') do |settings|
        $settings = settings
      end
      
      opts.on('-x', '--extensions PATH', 'Load extensions from the supplied folder, rather than from installed gems') do |path|
        $extensions_folder = path
      end
      
      opts.on('-r', '--reload', 'Reloads the server whenever any framework source files are modified') do
        $reload = true
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
      
      Yodel.config.extensions_folder = $extensions_folder if $extensions_folder
      Yodel.config.web_port = $web_port if $web_port
      
      if $env == 'production'
        Yodel.env.production!
      else
        Yodel.env.development!
      end
      
      if $reload
        require '../middleware/development_server'
        Rack::Server.start(app: DevelopmentServer.new, Port: Yodel.config.web_port)
      else
        require '../middleware/rack_server'
        require '../../yodel'
        Rack::Server.start(app: Application.new, Port: Yodel.config.web_port)
      end
  
    when 'dns'
      require '../requires'
      require './dns_server'
      DNSServer.start
  
    when 'console'
      require '../../yodel'
      require 'irb'
      
      Yodel.config.extensions_folder = $extensions_folder if $extensions_folder
      $application = Application.new
      IRB.start(__FILE__)
  
    when 'migrate'
      require '../../yodel'
      Yodel.config.extensions_folder = $extensions_folder if $extensions_folder
      $application = Application.new
      Migration.run_migrations_for_all_sites
    
    when 'deploy'
      require '../../yodel'
      Yodel.config.extensions_folder = $extensions_folder if $extensions_folder
      require './deploy'
      Deploy.new.deploy_site      
  
    when 'setup'
      require './installer'
      Installer.new.install_system_files
    
    when 'restart'
      require './restart'
      if Restart.can_restart?
        Restart.restart!
      else
        puts "Restart can only be run on OS X machines"
      end
      
    when 'update'
      require '../../yodel'
      require './restart'
      Yodel.config.extensions_folder = $extensions_folder if $extensions_folder
      $application = Application.new
      
      Migration.copy_missing_migrations_for_all_sites
      Migration.run_migrations_for_all_sites
      Restart.restart! if Restart.can_restart?
      
    else
      puts "Unknown command: #{command}"  
    end
  end
end
