class SiteDetector
  def initialize(app)
    @app = app
  end
  
  def call(env)
    request = Rack::Request.new(env)
    site = Site.find_by(domains: request.host)
    if site.nil?
      raise DomainNotFound.new(request.host, request.port)
    else
      env['yodel.site'] = site
      unless Yodel.env.development?
        env['rack.session.options'][:domain] = ".#{site.domains.first}"
      end
      @app.call(env)
    end
  end
end
