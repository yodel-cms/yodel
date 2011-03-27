module Yodel
  class Page < Record
    include Yodel::Authentication
    
    def flash
      @flash ||= Yodel::Flash.new
    end
    
    def form_for(record, options={}, &block)
      Yodel::FormBuilder.new(record, options, &block).render
    end
    
    
    # ----------------------------------------
    # Paths and permalinks
    # ----------------------------------------
    # permalinks are unique within the scope of the siblings of a page
    before_validation :assign_permalink
    def assign_permalink
      return unless title_changed? && title?
      base_permalink = title.parameterize(site.option('pages.permalink_character'))
      suffix = ''
      count  = 0
      
      # ensure other pages don't have the same path as this page
      page_siblings = siblings
      while page_siblings.any? {|page| page.permalink == base_permalink + suffix}
        count += 1
        suffix = "_#{count}"
      end
      
      # set the page's permalink, then construct its path and reset any child paths
      self.permalink = base_permalink + suffix
      assign_path
    end
    
    def assign_path(prefix=nil)
      if prefix
        new_prefix = prefix + '/' + permalink
      else
        new_prefix = '/' + parents.reverse[1..-1].collect(&:permalink).join('/')
      end
      
      self.path = new_prefix
      save_without_validation if prefix
      children.each {|child| child.assign_path(new_prefix)}
    end
    
    
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
      @_request   = request
      @_response  = response
      @_mime_type = mime_type
      
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
      
      # write the flash to the session if appropriate
      @flash.finalize if @flash
    end
    
    # basic environment accessors
    def request;        @_request; end
    def request=(r);    @_request = r; end;
    def env;            @_request.env; end
    def params;         @_request.params; end
    def response;       @_response; end
    def response=(r);   @_response = r; end
    def mime_type;      @_mime_type; end
    def mime_type=(m);  @_mime_type = m; end
    def session;        @_request.env['rack.session'] ||= {}; end

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
    # Default request handling
    # ----------------------------------------
    def to_form(url=nil, options={})
      options[:params] ||= {}
      options[:params][:_method] = new? ? 'post' : 'put'
      super(url || path, options)
    end
    
    def new_child_form(options={})
      default_child_model.new.to_form(path, options)
    end
    
    def delete_button(text, options={})
      attributes = options.collect {|name, value| "#{name}='#{value}'"}.join(' ')
      button_input = "<input type='submit' value=#{text}>"
      method_input = "<input type='hidden' name='_method' value='delete'>"
      "<form action='' method='post' #{attributes}>#{method_input}#{button_input}</form>"
    end
    
    def render
      @content ||= content
      layout.render(self)
    end
    
    def content
      @content ||= get_field('content')
    end
    
    def set_content(content)
      @content = content
    end
    
    def page
      self
    end
    
    def get_binding
      binding
    end
    
    # show
    respond_to :get do
      with :html do
        render
      end
      
      with :json do
        to_json
      end
    end
    
    # destroy
    respond_to :delete do
      with :html do
        response.redirect parent ? parent.path : '/'
        destroy
      end
      
      with :json do
        destroy
        {success: true}
      end
    end
    
    # update
    respond_to :put do
      with :html do
        # update the page assuming a form created by to_form
        path_was = path
        from_form(params)
        
        # updating the page can change its url
        if save && path != path_was
          respond.redirect path
        else
          render
        end
      end
      
      with :json do
        from_json(params['record'])
        if save
          to_json
        else
          # FIXME: need to show errors
          to_json
        end
      end
    end
    
    # create child
    respond_to :post do
      with :html do
        new_page = default_child_model.new
        new_page.parent = self
        new_page.from_form(params)
        
        if new_page.save
          flash[:create_successful] = true
          response.redirect new_page.path
        else
          if new_child_page
            new_child_page.request = request
            new_child_page.response = response
            flash.now(:child_page, new_page)
            new_child_page.respond_to_get_with_html
          else
            response.redirect request.referrer
          end
        end
      end
      
      with :json do
        new_page = default_child_model.new
        new_page.parent = self
        new_page.from_json(params['record'])
        if new_page.save
          new_page.to_json
        else
          {success: false}
        end
      end
    end

  end
end
