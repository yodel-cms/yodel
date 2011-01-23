module Yodel
  class Site
    include ::MongoMapper::Document
    has_many :records, class: Yodel::Model, dependent: :destroy
    has_many :routes, class: Yodel::Route
    
    key :name, String, required: true
    key :domains, Array, required: true, default: [], index: true
    key :extensions, Array, required: true, default: ['Pages', 'Admin']
    
    def self.find_by_domain(domain)
      where(domains: domain).first
    end
    
    def self.find_by_identifier(identifier)
      where(identifier: identifier).first
    end
    
    def reload_routes!
      self.routes = []
      
      # extensions.each... add route
      r = Yodel::Route.new
      r.method = 'any'
      r.path = '/'
      r.action = 'show'
      r.controller = 'PagesController'
      self.routes << r
      
      r = Yodel::Route.new
      r.method = 'any'
      r.path = '/admin/pages'
      r.action = 'show'
      r.controller = 'AdminController'
      self.routes << r
      
      # sort the routes in descending length (most descriptive routes
      # first before trying to match the least descriptive)
      self.routes = self.routes.sort_by {|route| -route.regex_path.length}
      self.routes.each_with_index {|route, index| route.index = index}
      self.save
    end
    
    def match_request(request)
      request_method = request.request_method.downcase
      path = request.path_info
      
      # find the first route that matches the request, fill in the
      # request params from data caputured in the url (such as ID)
      # and return the route that matches the request
      self.routes.each do |route|
        if match = route.match(path, request_method)
          match.names.each {|capture_name| request.params[capture_name] = match[capture_name]}
          return route
        end
      end      
      
      # no route matches the request
      nil
    end
    
    # Construct a path and method from a controller and action with
    # the passed options (e.g controller: PageController, action: show,
    # options: {path: /page/path})
    def path_and_method_for(controller, action, options)
      self.routes.each do |route|
        return route.path_with_options(options) if route.controller == controller && route.action == action
      end
      nil
    end
  end
end
