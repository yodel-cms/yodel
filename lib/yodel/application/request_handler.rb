module Yodel
  class RequestHandler
    def call(env)
      start = Time.now
      request  = Rack::Request.new(env)
      response = Rack::Response.new
      site = Site.find_by_domain(request.host)
      controller, action, match = Yodel.routes.match_request(request)

      unless controller.nil? || site.nil?
        controller.handle_request(request, response, site, action)
        finish = Time.now
        Yodel.config.logger.info "Request: #{request.url}; handling by #{controller.name} (#{finish.to_f - start.to_f})"
        response.finish
      else
        finish = Time.now
        Yodel.config.logger.info "Request: #{request.url}; 404 (#{finish.to_f - start.to_f})"
        [404, {"Content-Type" => "text/plain"}, ["URL Not Found: #{request.path}"]]
      end
    end
  end
end
