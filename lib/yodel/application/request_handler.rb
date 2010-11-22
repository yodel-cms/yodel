module Yodel
  class RequestHandler
    def call(env)
      Impromptu.update if Yodel.env.development?
      request  = Rack::Request.new(env)
      response = Rack::Response.new
      site = Yodel::Site.find_by_domain(request.host)
      controller, action, match = Yodel.routes.match_request(request) unless site.nil?
      
      unless site.nil? || controller.nil?
        controller.handle_request(request, response, site, action)
        response.finish
      else
        if site.nil?
          message = "Domain not found (#{request.host}). A Yodel::Site record must be mapped to this domain."
        else
          message = "URL not found for site with identifier: #{site.identifier}. Path: #{request.path}"
        end
        [404, {"Content-Type" => "text/plain"}, [message]]
      end
    end
  end
end
