Dir.chdir(File.dirname(__FILE__)) do
  require './request_handler'
  require './extension'
  require './yodel'
  require '../middleware/public_assets' if Yodel.env.development?
end

class Application < Rack::Builder
  def initialize
    super
    
    # boot
    Yodel.config.logger.info "Yodel starting up" if Yodel.env.production?
    Dir.chdir(Yodel.config.sites_root)
    Yodel.load_extensions
    
    # setup middleware
    use Rack::ShowExceptions if Yodel.env.development?
    use ErrorPages
    use Rack::Session::Cookie, key: Yodel.config.session_key, secret: Yodel.config.session_secret
    use Rack::NestedParams
    use Rack::MethodOverride
    use SiteDetector
    use PublicAssets if Yodel.env.development?
    
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
