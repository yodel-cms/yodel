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
    unless Yodel.env.development?
      Yodel.config.logger.info "Yodel starting up"
    end
    Yodel.load_extensions
    Dir.chdir(Yodel.config.root)
    
    # setup middleware
    use Rack::ShowExceptions if Yodel.env.development?
    use ErrorPages
    use Rack::Session::Cookie, key: Yodel.config.session_key, secret: Yodel.config.session_secret
    use Rack::NestedParams
    use Rack::MethodOverride
    use SiteDetector
    
    # TODO: no need to check these every request in development
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
    unless Yodel.env.development?
      Yodel.config.logger.info "Yodel startup complete"
    end
  end

  def call(env)
    @app.call(env)
  end
end
