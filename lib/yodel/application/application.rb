Dir.chdir(File.dirname(__FILE__)) do
  require 'yodel_config'
  require 'environment'
  require 'request_handler'
  require 'yodel'  
  require $settings_file unless $settings_file.nil?
  Yodel.config.merge_defaults!
end

class Application < Rack::Builder
  def initialize
    super
    
    # boot
    Yodel.load_extensions
    Dir.chdir(Yodel.config.root)
    
    # serve files from public in development. the directories are
    # initialised in reverse order so the apps public directory
    # takes first precedence over any extensions.
    if Yodel.env.development?
      Yodel.use_middleware do |app|
        Yodel.config.public_directories.reverse.each do |directory|
          app.use ConditionalFile, directory
        end
      end
    end
    
    # setup middleware
    use Rack::NestedParams
    use Rack::MethodOverride
    if Yodel.env.development?
      use Rack::Session::Cookie, key: Yodel.config.session_key, secret: Yodel.config.session_secret
    else
      # FIXME: need to do this once per site
      use Rack::Session::Cookie, key: Yodel.config.session_key, secret: Yodel.config.session_secret, domain: '.threadex.com.au'
    end
    Yodel.initialise_middleware_with_app(self)
    
    # check for any remaining migrations
    Migration.remaining_migrations.each do |site, remaining|
      next if remaining.empty?
      Yodel.config.logger.warn "Remaining migrations for site #{site.name}:"
      remaining.each {|name| Yodel.config.logger.warn name}
      Yodel.config.logger.warn ""
    end
    
    # FIXME: for production, load layouts once
    if Yodel.env.production?
      Site.all.each {|site| Layout.reload_layouts(site)}
    end
    
    # initialise a rack endpoint
    run RequestHandler.new
    @app = to_app
    
    # boot complete
    Yodel.config.logger.info "Yodel startup complete"
  end

  def call(env)
    @app.call(env)
  end
end
