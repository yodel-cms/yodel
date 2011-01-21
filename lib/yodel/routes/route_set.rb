module Yodel
  class RouteSet
    attr_reader :routes, :sorted
    def initialize
      @routes = []
      @sorted = false
    end
    
    def <<(route)
      @routes << Yodel::Route.new(route)
    end
    
    def sort_routes!
      last = @routes.select(&:last?).first
      @routes.delete(last) if !last.nil?
      @routes = @routes.sort_by {|route| -route.path.to_s.length}
      @routes << last unless last.nil?
      @sorted = true
    end
    
    def match_request(request)
      sort_routes! unless @sorted
      request_method = request.request_method.downcase.to_sym
      path = request.path_info
      
      @routes.each do |route|
        match = route.match(path, request_method)
        unless match.nil?
          merge_named_captures_with_params(match, request)
          return [route.controller, route.action, match]
        end
      end
      
      [nil, nil, nil]
    end
    
    def merge_named_captures_with_params(match, request)
      match.names.each do |capture_name|
        request.params[capture_name] = match[capture_name]
      end
    end
    
    def path_and_action_for(controller, action, options)
      @routes.each do |route|
        return route.path_with_options(options) if route.controller == controller && route.action == action
      end
      [nil, nil]
    end
  end
end
