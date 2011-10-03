require 'optparse'
Dir.chdir(File.dirname(__FILE__))

class CommandRunner
  def self.run
    OptionParser.new do |opts|
      opts.banner = "Usage: yodel [options] server|dns|console|migrate|setup"
      opts.on('-p', '--port PORT', Integer, 'Port to run the DNS or web server (default 80)') do |port|
        Yodel.config.port = port
      end
  
      opts.on('-e', '--environment ENV', 'Web server environment (default development)', 'development', 'production') do |env|
        if env == 'production'
          Yodel.env.production!
        else
          Yodel.env.development!
        end
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
      Rack::Server.start(app: DevelopmentServer.new, Port: 2828)
  
    when 'dns'
      require '../extras/dns_server'
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
  
    when 'setup'
      require './installer'
      Installer.install_system_files
      
    else
      puts "Unknown command: #{command}"  
    end
  end
end