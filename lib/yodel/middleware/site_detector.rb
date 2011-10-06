class SiteDetector
  def initialize(app)
    @app = app
  end
  
  def call(env)
    request = Rack::Request.new(env)
    site = Site.where(domains: request.host).first
    env['yodel.site'] = site
    
    if site.nil?
      raise DomainNotFound.new(request.host, request.port)
    else
      if !File.directory?(site.root_directory)
        raise MissingRootDirectory
      elsif Yodel.env.production?
        env['rack.session.options'][:domain] = ".#{site.domains.first}"
      end
    end
    
    @app.call(env)
  end
end
