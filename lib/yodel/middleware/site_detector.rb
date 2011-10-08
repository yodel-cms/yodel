class SiteDetector
  def initialize(app)
    @app = app
  end
  
  def call(env)
    request = Rack::Request.new(env)
    site = Site.where(domains: request.host).first
    env['yodel.site'] = site
    
    unless site.nil?
      if Yodel.env.production?
        raise MissingRootDirectory.new(site, request.port) if !File.directory?(site.root_directory)
        env['rack.session.options'][:domain] = ".#{site.domains.first}"
      end
    else
      raise DomainNotFound.new(request.host, request.port) if Yodel.env.production?
    end
    
    @app.call(env)
  end
end
