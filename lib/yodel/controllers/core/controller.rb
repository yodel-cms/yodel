module Yodel
  class Controller
    def initialize(request, response, site)
      @request, @response, @site = request, response, site
    end
    
    def self.handle_request(request, response, site, action)
      controller = self.new(request, response, site)
      run_before_filters(controller, action)
      controller.send(action)
      run_after_filters(controller, action)
      controller.write_response(action)
    end
    
    # basic environment accessors
    def env;      @request.env; end
    def request;  @request; end
    def params;   @request.params; end
    def response; @response; end
    def site;     @site; end
    def session;  @env['rack.session'] ||= {}; end
    
    
    # before filters are run before the controller performs an action
    # after filters are run after the action has finished running
    def self.before_filters; @before_filters ||= []; end
    def self.after_filters; @after_filters ||= []; end
    
    def self.before_filter(method, options={})
      before_filters << [method, options]
    end
    
    def self.after_filter(method, options={})
      after_filters << [method, options]
    end
    
    def self.run_before_filters(context, action)
      before_filters.each do |method, options|
        if !options.empty?
          next if options[:only] && ![*options[:only]].include?(action)
          next if options[:except] && [*options[:except]].include?(action)
        end
        context.send(method)
      end
    end
    
    def self.run_after_filters(context, action)
      after_filters.each do |method, options|
        if !options.empty?
          next if options[:only] && ![*options[:only]].include?(action)
          next if options[:except] && [*options[:except]].include?(action)
        end
        context.send(method)
      end
    end
        
    def self.inherited(child)
      super(child)
      child.instance_variable_set('@before_filters', @before_filters)
      child.instance_variable_set('@after_filters', @after_filters)
    end
    
    # rendering
    # TODO: possible cleanup: why have extra context and context object; just force callers to construct a context object anyway?
    def render_file(file, context=nil, extra_context={})
      File.open(file, 'r') do |file|
        render_string file.read, context, extra_context
      end
    end
    
    def render_string(markup, context=nil, extra_context={})
      if context.nil?
        context = RenderContext.new(self, extra_context)
      end
      Erubis::Eruby.new(markup).evaluate(context)
    end
    
    
    # controller routes
    # FIXME: needs to take a site parameter
    def self.route(path, options={})
      Yodel.routes << {controller: self, method: :any, action: :index, path: path}.merge(options)
    end
    
    def self.path_and_action_for(action, options={})
      Yodel.routes.path_and_action_for(self, action, options)
    end
    
    
    # content and status code assignment
    def status(code)
      response.status = code
    end
    
    def method_missing(name, *args, &block)
      # ensure the mime type is valid
      mime_type = Yodel.mime_types.type(name)
      raise "Unknown Mime Type: #{name}" if mime_type.nil?
      @responses ||= {}
      
      # values can be a block (evaluated only if the request is for this
      # mime type), anything that responds to .to_s, or nothing (blank response)
      if block_given?
        @responses[name] = block
      elsif args.length == 1
        @responses[name] = args.first
      else
        @responses[name] = ''
      end
    end
    
    # Each action may provide more than one response depending on the type of
    # request (e.g html for a normal request, and JSON for an API request). This
    # method finds the first response matching the request and writes it to the
    # client. Any block based responses are only evaluated if they match the
    # request, and if no matching response can be found, we fall back to sending
    # the first response we know about (typically HTML)
    def write_response(action)
      return unless response.empty?
      if @responses.nil?
        if response.status != 200
          response.write "Error: #{response.status}" and return
        else
          raise "No response provided for this request (#{self.class.name}##{action})"
        end
      end
      
      # find the first response which matches the current request,
      # process it with a builder and transformer for the mime type
      # if required, and write the response
      @responses.each do |name, data|
        mime_type = Yodel.mime_types.type(name)
        if mime_type.matches_request?(request)
          data = data.call(mime_type.create_builder) if data.is_a? Proc
          response.write mime_type.process(data)
          response['Content-Type'] = mime_type.default_mime_type
          return
        end
      end
      
      # no response matches the request, so respond with the first
      # response data we have, showing a warning
      Yodel.config.logger.warn "No response matches this request, falling back to #{@responses.keys.first}"
      name = @responses.keys.first
      data = @responses[name]
      mime_type = Yodel.mime_types.type(name)
      data = data.call(mime_type.create_builder) if data.is_a? Proc
      response.write mime_type.process(data)
      response['Content-Type'] = mime_type.default_mime_type
    end
  end
end
