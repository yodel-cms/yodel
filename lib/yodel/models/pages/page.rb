class Page < Record
  include Authentication
  
  # ----------------------------------------
  # Paths and permalinks
  # ----------------------------------------
  # Permalinks are unique within the scope of the siblings of a page. Only reassign
  # a permalink after a title has changed, or if the title is a function type (and
  # could change on every update of the page).
  before_validation :assign_permalink
  def assign_permalink
    return unless (title_changed? && title?) || (!title.nil? && values['title'].nil?)
    
    # until we detect changes to fields used by cached functions, force a refresh of the value
    generate_unloaded_field('title') if field('title').type == 'Function'
    
    permalink_character = site.option('pages.permalink_character') || '-'
    base_permalink = title.parameterize(permalink_character)
    suffix = ''
    count  = 0
    
    # ensure other pages don't have the same path as this page
    page_siblings = siblings.all.select {|record| record.field?('permalink')}
    while page_siblings.any? {|page| page.permalink == base_permalink + suffix}
      count += 1
      suffix = "#{permalink_character}#{count}"
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
    count = 0
    
    while site.pages.where(:path => self.path, :_id.ne => self.id).exists?
      count += 1
      self.path = "#{new_prefix}#{count}"
    end
    
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
  
  def flash
    @flash ||= Flash.new(session)
  end
  
  def form_for(record, action, options={}, &block)
    options[:method] = record.new? ? 'post' : 'put'
    action += '.json' if options[:remote] # FIXME: doesn't work if the path ends with a query string
    FormBuilder.new(record, action, options, &block).render
  end
  
  def form_for_page(options={}, &block)
    options[:method] = new? ? 'post' : 'put'
    form_path = path_was
    form_path += '.json' if options[:remote] # FIXME: doesn't work if the path ends with a query string
    form_for(self, form_path, options, &block)
  end
  
  def immediately(action, options={})
    action_record = options.delete(:record)
    action_path = options.delete(:path)
    
    # remaining options are field mutations
    fields = fields_to_json(options)
    
    # perform the action directly on a record
    if action_path.nil?
      action_record ||= self
      action_record.from_json(fields)
      action_record.save
      ''
    else
      Hpricot::Elem.new('script', {}, [
        Hpricot::Text.new(action_to_javascript(action, action_path, fields))
      ])
    end
  end
  
  def on_click(action, options={}, &block)
    # on_click requires child elements
    return '' unless block_given?
    
    # determine the path and fields of the request
    action_record = options.delete(:record) || self
    action_path   = options.delete(:path) || action_record.path
    fields        = fields_to_json(options)
    
    Ember::Template.wrap_content_block(block) do |content|
      Hpricot::Elem.new('span', {
        'class' => 'yodel-remote-action',
        'data-action' => CGI.escape_html(action_to_javascript(action, action_path, fields))
      }, [Hpricot::Text.new(content.join)])
    end
  end
  
  def fields_to_json(fields)
    fields.each_with_object({}) do |(key, value), hash|
      field_action = value.keys.first.to_s
      field_value = value[value.keys.first]
      hash[key.to_s] = {'_action' => field_action, '_value' => field_value}
    end
  end
  private :fields_to_json
  
  def action_to_javascript(action, path, fields)
    case action
    when :update
      "Yodel.Records.update('#{path}', #{fields.to_json});"
    when :delete
      "Yodel.Records.delete('#{path}');"
    end
  end
  private :action_to_javascript
  
  
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
    response['Content-Type'] = "#{mime_type.default_mime_type}; charset=utf-8"
    
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
  
  # FIXME: make layout take a string or symbol param, remove .to_s from render_or_default, change blog.rb layout to use a symbol not string, check all other calls to layout() and change appropriately
  # Determine the first best layout to be used by this page for rendering
  def layout(mime_type, editing=false)
    # if we're in production we'll have a reference to a layout record
    #return page_layout_record if page_layout_record # FIXME: implement layout caching
    
    # try and return a layout by name or by the name of the page's class
    layout_name = editing ? edit_layout : page_layout
    layout = site.layouts.where(name: layout_name, mime_type: mime_type).first
    
    unless layout
      layout_name = model.name.underscore
      layout_name = "edit_#{layout_name}" if editing
      layout = site.layouts.where(name: layout_name, mime_type: mime_type).first
    end
    
    return layout if layout
    
    # otherwise fall back to the parent's layout
    return parent.layout(mime_type) unless parent.nil?
    raise LayoutNotFound
  end
  
  def render_layout(name, mime_type)
    layout_record = site.layouts.where(name: name, mime_type: mime_type).first
    raise LayoutNotFound if layout_record.nil?
    layout_record.render(self)
  end
  

  # ----------------------------------------
  # Default request handling
  # ----------------------------------------
  def delete_button(text, options={})
    attributes = ""
    if options[:confirm]
      attributes << " onsubmit='return confirm(\"#{options.delete(:confirm)}\")'"
    end
    attributes << options.collect {|name, value| "#{name}='#{value}'"}.join(' ')
    button_input = "<button>#{text}</button>"
    method_input = "<input type='hidden' name='_method' value='delete'>"
    "<form action='#{path}' method='post' #{attributes}>#{method_input}#{button_input}</form>"
  end
  
  def delete_link(text, options={})
    attributes = ""
    if options[:confirm]
      confirm = "if(confirm(\"#{options.delete(:confirm)}\"))"
    else
      confirm = ''
    end
    if options[:wrap]
      wrap_start = options[:wrap][0]
      wrap_end = options[:wrap][1]
      options.delete(:wrap)
    else
      wrap_start = ''
      wrap_end = ''
    end
    attributes << options.collect {|name, value| "#{name}='#{value}'"}.join(' ')
    delete_link = "#{wrap_start}<a #{attributes} onclick='#{confirm}submit()'>#{text}</a>#{wrap_end}"
    method_input = "<input type='hidden' name='_method' value='delete'>"
    "<form action='#{path}' method='post' class='delete'>#{method_input}#{delete_link}</form>"
  end
  
  def render_or_default(mime_type, &block)
    @content ||= content
    editing = @_request && params && params['action'] == 'edit'
    layout(mime_type.to_s, editing).render(self)
  rescue LayoutNotFound
    yield
  end
  
  def set_content(content)
    @content = content
  end
  
  def content(*section)
    if section.empty?
      @content ||= get('content')
    else
      instance_variable_get("@content_for_#{section.first}") || ''
    end
  end
  
  def content_for(section, options={}, &block)
    if block_given?
      content = Ember::Template.content_from_block(block).join
    elsif options.key?(:partial)
      content = partial(options[:partial])
    end
    instance_variable_set("@content_for_#{section}", content)
  end
  
  def partial(name)
    name = name.to_s
    name = name + '.html' unless name.end_with?('.html')
    path = site.partials_directory.join(name)
    raise LayoutNotFound, path unless File.exist?(path)
    Ember::Template.new(IO.read(path), {source_file: path}).render(get_binding)
  end
  
  def page
    self
  end
  
  def user_allowed_to?(action)
    allowed = super(current_user, action)
    return true if allowed

    session[:redirect_to_after_login] = self.path
    response.redirect site.login_pages.first.path
    flash[:permission_denied] = action
    false
  end
  
  # show
  respond_to :get do
    with :html do
      return unless user_allowed_to?(:view)
      render_or_default(:html) { raise LayoutNotFound }
    end
    
    with :json do
      return unless user_allowed_to?(:view)
      render_or_default(:json) do
        to_json
      end
    end
  end
  
  # destroy
  respond_to :delete do
    with :html do
      return unless user_allowed_to?(:delete)
      response.redirect parent ? parent.path : '/'
      destroy
    end
    
    with :json do
      return unless user_allowed_to?(:delete)
      destroy
      {success: true}
    end
  end
  
  # update
  respond_to :put do
    with :html do
      return unless user_allowed_to?(:update)
      
      # update the page assuming a form created by to_form
      path_was = path
      success = from_json(params)
      
      # updating the page can change its url
      if success && (path != path_was)
        flash[:performed_update] = true
        flash[:update_successful] = success
        response.redirect path
      else
        flash.now(:performed_update, true)
        flash.now(:update_successful, success)
        render_or_default(:html) { raise LayoutNotFound }
      end
    end
    
    with :json do
      return unless user_allowed_to?(:update)
      if params.key?('record')
        values = JSON.parse(params['record'])
      else
        values = params
      end
      
      if from_json(values)
        render_or_default(:json) do
          {success: true, record: self}
        end
      else
        render_or_default(:json) do
          {success: false, errors: errors}
        end
      end
    end
  end
  
  # DOC TIP: make sure a title is set or no path will be generated and this action will fail Rack::Lint
  
  # create child
  respond_to :post do
    with :html do
      return unless user_allowed_to?(:create)
      new_page = model.default_child_model.new
      new_page.parent = self
      
      if new_page.from_json(params)
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
      return unless user_allowed_to?(:create)
      new_page = model.default_child_model.new
      new_page.parent = self
      
      if params.key?('record')
        values = JSON.parse(params['record'])
      else
        values = params
      end
      
      if new_page.from_json(values)
        new_page.render_or_default(:json) do
          {success: true, record: new_page}
        end
      else
        new_page.render_or_default(:json) do
          {success: false, errors: new_page.errors}
        end
      end
    end
  end

end
