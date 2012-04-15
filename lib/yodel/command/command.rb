require 'optparse'
Dir.chdir(File.dirname(__FILE__))
Encoding.default_external = "utf-8"

class CommandRunner
  def self.run
    OptionParser.new do |opts|
      opts.banner = "Usage: yodel [options] server|dns|restart|console|queue|migrate|deploy|setup|update"
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
      setup!(false)
      
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
      setup!
      IRB.start(__FILE__)
    
    when 'queue'
      require '../../yodel'
      setup!
      QueueDaemon.run
      
    when 'migrate'
      require '../../yodel'
      setup!
      Migration.run_migrations_for_all_sites
    
    when 'deploy'
      require '../../yodel'
      require './deploy'
      $env = 'production' # override env since deploys only happen in production
      setup!
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
      setup!
      
      Migration.copy_missing_migrations_for_all_sites
      Migration.run_migrations_for_all_sites
      Restart.restart! if Restart.can_restart?
      
    else
      if command.blank?
        puts "No command given"
      else
        puts "Unknown command: #{command}"
      end
    end
  end
  
  def self.setup!(create_application = true)
    Yodel.config.extensions_folder = $extensions_folder if $extensions_folder
    Yodel.config.web_port = $web_port if $web_port
    Yodel.env.production! if $env == 'production'
    Yodel.env.development! if $env == 'development'
    $application = Application.new if create_application
  end
end
