module Yodel
  class RequestHandler
    def call(env)
      # reload yodel, extension and application files each request
      Impromptu.update if Yodel.env.development?
      
      # find the site this request is for
      request  = Rack::Request.new(env)
      response = Rack::Response.new
      site = Yodel::Site.find_by_domain(request.host)
      
      # attempt to find a matching route for this request
      return fail_with "Domain (#{request.host}) not found. Add a Site record for this domain." if site.nil?
      site.reload_routes! if Yodel.env.development?
      route = site.match_request(request)
      return fail_with "Path (#{request.path}) not found for this site (#{site.name})." if route.nil?
      
      # run the matching controller action
      begin
        controller = Object.module_eval(route.controller)
        controller.handle_request(request, response, site, route.action)
        response.finish
      rescue NameError
        return fail_with "Unknown controller (#{route.controller}) for path (#{route.original_path})"
      end
    end
    
    def fail_with(message)
      [404, {"Content-Type" => "text/plain"}, [message]]
    end
  end
end
