module Yodel
  class RequestHandler
    PATH_FORMAT_REGEX = /^(?<path>.*?)(\.(?<format>\w+))?$/
    
    def call(env)
      # in development all yodel files, extensions, and application files are reloaded each request
      Impromptu.update if Yodel.env.development?
      
      # find the site this request is for
      request  = Rack::Request.new(env)
      response = Rack::Response.new
      site = Yodel::Site.find_by(domains: request.host)
      return fail_with "Domain (#{request.host}) not found. Add a Site record for this domain." if site.nil?
      
      # split the request path into a standard path and trailing file extension if present
      components = PATH_FORMAT_REGEX.match(request.path)
      return fail_with "Unable to parse request path: #{request.path}" if components.nil?
      path, format = components.captures
      path = path[0...-1] if path.end_with?('/') && path.length != 1
      
      # match the request to the closest mime type we're aware of
      mime_type = Yodel.mime_types.mime_type_for_request(format, request.env['HTTP_ACCEPT'])
      
      # attempt to find a matching page for this request
      page = site.pages.where(path: path).first
      return fail_with "Path (#{request.path}) not found for this site (#{site.name})." if page.nil?
      Yodel::Layout.reload_layouts(site) if Yodel.env.development?
      page.respond_to_request(request, response, mime_type)
      response.finish
    end
    
    def fail_with(message)
      [404, {"Content-Type" => "text/plain"}, [message]]
    end
  end
end
