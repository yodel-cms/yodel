# Classes including this module must implement this interface:
# path: path to the current page
# path_was: original path to the current page (if path has been updated)
# form_for_page must be called in a context where form_for is available
module HTMLDecorator
  # ----------------------------------------
  # Forms
  # ----------------------------------------
  def form_for_page(options={}, &block)
    # FIXME: record proxy page needs to implement form_for with 3 parameters, not 2
    if method(:form_for).arity == -3
      form_for(self, path_was, options, &block)
    else
      form_for(self, options, &block)
    end
  end
  
  
  # ----------------------------------------
  # Actions
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
    delete_link = "#{wrap_start}<a #{attributes} onclick='#{confirm}submit()' href='#'>#{text}</a>#{wrap_end}"
    method_input = "<input type='hidden' name='_method' value='delete'>"
    "<form action='#{path}' method='post' class='delete'>#{method_input}#{delete_link}</form>"
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
  
  # fields is a hash containing a set of fields to change, the
  # operation to perform, and the value to perform the operation
  # with, for example: {age: {set: 40}, name: {set: 'Bob'}}
  # The return value is a hash representing the same set of changes,
  # formatted in a way Record#from_json responds to.
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
  # Formatters
  # ----------------------------------------
  def paragraph(index, options={})
    text = self.send(options[:field] || :content)
    paragraphs = Hpricot(text).search('/p')
    return '' if paragraphs.nil? || paragraphs[index].nil?
    if options[:strip]
      paragraphs[index].search('//text()').join
    else
      paragraphs[index].inner_html
    end
  end
  
  def paragraphs_from(index, options={})
    text = self.send(options[:field] || :content)
    paragraphs = Hpricot(text).children
    return '' if paragraphs.nil? || paragraphs[index..-1].nil?
    if options[:strip]
      paragraphs[index..-1].collect {|p| p.search('//text()').join}.join
    else
      paragraphs[index..-1].collect {|p| p.to_s}.join
    end
  end
end
