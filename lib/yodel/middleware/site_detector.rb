class SiteDetector
  def initialize(app)
    @app = app
  end
  
  def call(env)
    request = Rack::Request.new(env)
    site = Site.where(domains: request.host).first
    env['yodel.site'] = site
    unless site.nil? || Yodel.env.development?
      env['rack.session.options'][:domain] = ".#{site.domains.first}"
    end
    @app.call(env)
  end
end
