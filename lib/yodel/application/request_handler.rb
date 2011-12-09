class RequestHandler
  PATH_FORMAT_REGEX = /^(?<path>.*?)(\.(?<format>\w+))?$/
  
  def call(env)
    # find the site this request is for
    request  = Rack::Request.new(env)
    response = Rack::Response.new
    site = env['yodel.site']

    # temporary workaround to force rack to write the session out to a cookie
    env['rack.session']['a'] = 1

    # split the request path into a standard path and trailing file extension if present
    components = PATH_FORMAT_REGEX.match(request.path)
    return fail_with "Unable to parse request path: #{request.path}" if components.nil?
    path, format = components.captures
    path = path[0...-1] if path.end_with?('/') && path.length != 1
    
    # match the request to the closest mime type we're aware of
    mime_type = Yodel.mime_types.mime_type_for_request(format, request.env['HTTP_ACCEPT'])
    
    # attempt to find a matching page for this request
    page = site.pages.where(path: path).first
    if page.nil?
      site.glob_pages.all.each do |glob_page|
        if path.start_with?(glob_page.path)
          page = glob_page
          request.params['glob'] = path[glob_page.path.length..-1]
          break
        end
      end
      return fail_with "File (#{request.path}) not found." if page.nil?
    end
    
    # respond
    Layout.reload_layouts(site) if Yodel.env.development? # FIXME: implement production caching
    page.respond_to_request(request, response, mime_type)
    if page.response.respond_to?(:finish)
      page.response.finish
    else
      page.response
    end
  end
  
  def fail_with(message)
    [404, {'Content-Type' => 'text/plain'}, [message]]
  end
end
