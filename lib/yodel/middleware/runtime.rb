# handles requests to the 'yodel' domain
class Runtime
  CREATE_SITE_PATH = /^\/create_site\/(?<name>.+)\.yodel$/
  
  def initialize(app)
    @app = app
  end
  
  def call(env)
    request = Rack::Request.new(env)
    
    # runtime is the last middleware before the main yodel
    # request handler. domain not found exceptions are
    # raised from here and not from the site_detector
    # middleware, so the public assets middleware has a
    # chance to respond before the exception is raised.
    # runtime pages depend on this.
    if env['yodel.site'].nil?
      raise DomainNotFound.new(request.host, request.port)
    end
    
    # handle the create_site command
    if request.host == 'yodel'
      if request.path =~ CREATE_SITE_PATH
        create_site($1, request)
      else
        return [500, {'Content-Type' => 'text/html'}, ["Unknown Request"]]
      end
    else
      @app.call(env)
    end
  end
  
  def create_site(name, request)
    # create the new site
    site = Site.new
    site.name = name
    site.domains << "#{name}.yodel"
    site.save
    
    # run standard migrations
    Migration.run_migrations(site)
    
    # redirect to the new site
    response = Rack::Response.new
    port = (request.port == 80 ? nil : request.port)
    response.redirect "http://#{name}.yodel#{':' if port}#{port}/admin/pages"
    response.finish
  end
end
