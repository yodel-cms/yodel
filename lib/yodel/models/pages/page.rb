module Yodel
  class Page < Record
    include Yodel::Authentication
    
    # ----------------------------------------
    # Paths and permalinks
    # ----------------------------------------
    #     # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #     # TODO: whenever a permalink changes on a top level page, children need their paths to be updated
    #     # the path of the current page also needs to be updated
    #     
    #     # permalinks are unique within the scope of the siblings of a page
    #     before_validation_on_create :assign_permalink
    #     def assign_permalink
    #       return if self.title.blank?
    #       base_permalink = self.title.parameterize('_')
    #       suffix = ''
    #       count  = 0
    #       
    #       # ensure other pages don't have the same path as this page
    #       page_siblings = self.siblings
    #       while !page_siblings.select {|page| page.permalink == base_permalink + suffix}.empty?
    #         count += 1
    #         suffix = "_#{count}"
    #       end
    #       
    #       self.permalink = base_permalink + suffix
    #     end
    
    
    # ----------------------------------------
    # Layout helpers
    # ----------------------------------------
    def snippet(name)
      site.snippets.where(name: name).first
    end
    
    def paragraph(index, field=:content)
      text = self[field]
      paragraphs = Hpricot(text).search('/p')
      return '' if paragraphs.nil? || paragraphs[index].nil?
      paragraphs[index].inner_html
    end
    
    def paragraphs_from(index, field=:content)
      text = self[field]
      paragraphs = Hpricot(text).children
      return '' if paragraphs.nil? || paragraphs[index..-1].nil?
      paragraphs[index..-1].collect {|p| p.to_s}.join('')
    end
    
        
    # ----------------------------------------
    # Response content
    # ----------------------------------------
    def self.respond_to(http_method)
      # FIXME: this is not thread safe
      @_http_method = http_method
      yield
      @_http_method = nil
    end
    
    def self.with(mime_type, &block)
      # two instance methods may be defined from the response definition
      action_name             = "respond_to_#{@_http_method}_with_#{mime_type}"
      default_action_name     = "default_response_to_#{@_http_method}"
      default_action_mime_var = "@default_response_to_#{@_http_method}_mime_type"
      
      # create or overwrite the main action for this http_method/mime_type pair
      define_method(action_name, block)
      
      # if this is the first response definition for the http_method, assign it
      # as the default response for requests matching the http_method, but not
      # matching a mime_type that has been responded to
      unless instance_methods(false).include?(default_action_name.to_sym)
        define_method(default_action_name, block)
        instance_variable_set(default_action_mime_var, Yodel.mime_types[mime_type])
      end
    end
    
    # request handling
    def respond_to_request(request, response, mime_type)
      # initialise request & response for use by the environment accessors
      @_request  = request
      @_response = response
      
      # determine the default action name for the request
      http_method = request.request_method.downcase
      action = "respond_to_#{http_method}_with_#{mime_type.name}"
      
      # if there is no action for the request, default to the first for the http_method of the request
      if !respond_to?(action)
        action = "default_response_to_#{http_method}"
        
        if !respond_to?(action)
          response.write "Unable to respond to a request using http method: #{http_method}"
          response['Content-Type'] = 'text/plain'
          return
        else
          default_mime = self.class.instance_variable_get("@default_response_to_#{http_method}_mime_type")
          mime_type = default_mime if mime_type != default_mime
          Yodel.config.logger.warn "No response matches this request, falling back to a default response."
        end
      end
      
      # only send a builder object as a parameter to the action if required
      if mime_type.has_builder?
        data = send(action, mime_type.create_builder)
      else
        data = send(action)
      end
      
      # process the response and set headers
      response.write mime_type.process(data)
      response['Content-Type'] = mime_type.default_mime_type
    end
    
    # basic environment accessors
    def env;      @_request.env; end
    def request;  @_request; end
    def params;   @_request.params; end
    def response; @_response; end
    def session;  @_request.env['rack.session'] ||= {}; end

    # By default, responses are assumed to be 200 (successful). Use
    # status to change the code returned along with your response content.
    def status(code)
      response.status = code
    end

    # Determine the first best layout to be used by this page for rendering
    def layout
      # if we're in production we'll have a reference to a layout record
      return page_layout_record if page_layout_record
      
      # try and return a layout by name or by the name of the page's class
      layout = site.layouts.where(name: page_layout).first
      layout = site.layouts.where(name: model.name.underscore).first unless layout
      return layout if layout
      
      # otherwise fall back to the parent's layout
      return parent.layout unless parent.nil?
      raise Yodel::LayoutNotFound
    end
    

    # ----------------------------------------
    # Default rendering
    # ----------------------------------------
    def render
      layout.render(self)
    end
    
    def set_content(content)
      @content = content
    end
    
    def get_content
      @content
    end
        
    respond_to :get do
      with :html do
        render
      end
      
      with :json do
        raw_values
      end
    end

  end
end
