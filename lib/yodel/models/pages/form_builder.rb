class FormBuilder
  MONTHS = [
    [1, "January"],
    [2, "February"],
    [3, "March"],
    [4, "April"],
    [5, "May"],
    [6, "June"],
    [7, "July"],
    [8, "August"],
    [9, "September"],
    [10, "October"],
    [11, "November"],
    [12, "December"]
  ]
  
  
  def initialize(record, action, options={}, &block)
    @record = record
    @options = options
    @block = block
    @action = action
    
    @remote = options.delete(:remote)
    @method = options.delete(:method) || 'post'
    @params = options.delete(:params) || {}
    @embedded_record = options.delete(:embedded_record)
    @blank_record = options.delete(:blank_record)
    @prefix = options.delete(:prefix)
    @id = options.delete(:id) || "form_for_#{record.id}"
  end
  
  
  def form_for_section(section)
    buffer = Ember::Template.buffer_from_block(@block)
    @record.fields.each do |name, field|
      next unless field.display? && field.section == section && field.default_input_type.present? && field.default_input_type != :embedded
      buffer << "<div class='contains-field-type-#{field.options['type']}'>" << label(name) << "<div>" << field(name) << status(name) << "</div></div>"
    end
    ''
  end
  
  
  def field(name, options={}, &block)
    invalid = @record.errors.key?(name.to_s)
    field_name = name.to_s
    field = @record.field(field_name)
    input_name = (options.delete(:name) || field_name).to_s
    input_name = "#{@prefix}[][#{input_name}]" if @prefix
    value = options.delete(:value) || @record.get(field_name)
    type = options.delete(:as) || field.default_input_type
    
    case type
    when :text, :password, :hidden
      value = nil if type == :password
      value = value.id if value.is_a?(AbstractRecord)
      element = build_element(:input, {type: type.to_s, value: value.to_s})
    when :textarea
      element = build_element(:textarea, {}, value.to_s)
    when :html
      element = build_element(:textarea, {class: 'html'}, value.to_s)
    when :radio
      base = {type: 'radio', name: input_name}
      true_button   = build_element(:input, base.merge(condition('checked', value, ['true', true])))
      false_button  = build_element(:input, base.merge(condition('checked', value, ['false', false])))
      true_text     = options.delete(:true) || 'Yes'
      false_text    = options.delete(:false) || 'No'
      element = build_element(:span, {}, [true_text, true_button, false_text, false_button])
    when :enum
      element = build_select(value, field.options['options'], show_blank: field.show_blank, blank_text: field.blank_text)
    when :store_one
      element = build_select(value, field.record_options(@record), show_blank: field.show_blank, blank_text: field.blank_text, group_by: field.group_by, name_field: 'name', value_field: 'id')
    when :store_many
      element = build_select(value.collect(&:id), field.record_options(@record), show_blank: false, name_field: 'name', value_field: 'id', multiple: true)
      input_name += '[]'
    when :date, :datetime
      # day
      day_select = build_select(value.try(:day).to_s, (1..31), show_blank: true, blank_text: '', name_field: 'to_s', value_field: 'to_s')
      day_select.set_attribute(:name, input_name + '[day]')
      day_select.set_attribute(:id, input_name + '_day_')
      
      # month
      month_select = build_select(value.try(:month).to_s, MONTHS, show_blank: true, blank_text: '', name_field: 'last', value_field: 'first')
      month_select.set_attribute(:name, input_name + '[month]')
      month_select.set_attribute(:id, input_name + '_month_')
      
      # year
      year_select = build_select(value.try(:year).to_s, ((Time.now.year - 100)..(Time.now.year + 10)), show_blank: true, blank_text: '', name_field: 'to_s', value_field: 'to_s')
      year_select.set_attribute(:name, input_name + '[year]')
      year_select.set_attribute(:id, input_name + '_year_')
      
      elements = [day_select, month_select, year_select]
      if type == :datetime
        # hour
        hour_select = build_select(value.try(:hour).to_s, (0..23), show_blank: true, blank_text: '', name_field: 'to_s', value_field: 'to_s')
        hour_select.set_attribute(:name, input_name + '[hour]')
        hour_select.set_attribute(:id, input_name + '_hour_')
        
        # minute
        min_select = build_select(value.try(:min).to_s, (0..59), show_blank: true, blank_text: '', name_field: 'to_s', value_field: 'to_s')
        min_select.set_attribute(:name, input_name + '[min]')
        min_select.set_attribute(:id, input_name + '_min_')
        
        elements += [hour_select, min_select]
      end
      
      element = build_element(:span, {}, elements)
    when :embedded
      if block_given?
        if value.respond_to?(:each)
          value.each do |document|
            self.class.new(document, @action, {embedded_record: field, prefix: name, id: @id}, &block).render
          end
        else
          self.class.new(value, @action, {embedded_record: field, prefix: name, id: @id}, &block).render
        end
      
        if options.delete(:blank_record)
          self.class.new(value.new, @action, {embedded_record: field, blank_record: true, prefix: name, id: @id}, &block).render
        end
      end
      
      buffer = Ember::Template.buffer_from_block(@block)
      buffer << build_element(:input, {'type' => 'hidden', 'data-field' => input_name}).to_s
    end
    
    element.tap do |element|
      class_name = invalid ? 'invalid' : (@record.new? ? 'new' : 'valid')
      class_name += " field-type-#{field.options['type']}"
      element.set_attribute(:id, input_name.gsub(/\W/, '_'))
      element.set_attribute(:name, input_name)
      element.set_attribute(:class, class_name)
      element.set_attribute(:placeholder, field.placeholder || '')
      element.set_attribute('data-field', input_name)
      options.each do |name, value|
        element.set_attribute(name.to_s, value)
      end
    end if element
  end
  
  def record
    @record
  end
  
  
  def label(name, text=nil, options={})
    text ||= name.to_s.humanize
    build_element(:label, {:for => name.to_s}, text)
  end

  
  def status(*params)
    if params.last.is_a?(Hash)
      handles = params[0...-1]
      options = params.last
    else
      handles = params
      options = {}
    end
    
    handles       = handles.collect(&:to_s)
    name          = options.delete(:as) || handles.first
    new_text      = options.delete(:new).to_s
    valid_text    = options.delete(:valid).to_s
    invalid_text  = options.delete(:invalid).to_s
    
    if @record.errors.empty?
      state = 'new'
      message = new_text
    elsif handles.any? {|name| @record.errors.key?(name)}
      state = 'invalid'
      unless invalid_text.blank?
        message = invalid_text
      else
        message = handles.collect {|name| @record.errors.summarise[name]}.compact.join(', ')
      end
    else
      state = 'valid'
      message = valid_text
    end
    
    render_status(name, handles.join(' '), message, state, new_text, valid_text, invalid_text)
  end
  
  def progress(&block)
    Ember::Template.wrap_content_block(block) do |content|
      Hpricot::Elem.new('span', {
        :class => 'yodel-form-activity',
        :style => 'visibility: hidden'
      }, [Hpricot::Text.new(content.join)])
    end
  end
  
  def success(&block)
    define_callback_function('success', 'record', block)
  end
  
  def errors(&block)
    define_callback_function('errors', 'errors', block)
  end
  
  def failure(&block)
    define_callback_function('failure', 'xhr', block)
  end
  
  def statuses(&block)
    @status_template = block
  end
  
  def blank_record?
    @blank_record
  end
  
  def render
    if @embedded_record
      buffer = Ember::Template.buffer_from_block(@block)
      buffer << Ember::Template.content_from_block(@block, self)
    else
      Ember::Template.wrap_content_block(@block, self) do |content|
        params = {
          'action' => @action,
          'method' => 'post',
          'data-remote' => (!!@remote).to_s,
          'data-success-function' => @success_function.to_s,
          'data-errors-function' => @errors_function.to_s,
          'data-failure-function' => @failure_function.to_s
        }.merge(@params)
        
        Hpricot::Elem.new('form', params, [
          Hpricot::Text.new(content.join),
          Hpricot::Elem.new('input', {type: 'hidden', name: '_method', value: @method})
        ])
      end
    end
  end
  
  
  private
    def render_status(name, handles, message, state, new_text, valid_text, invalid_text)
      if @status_template
        element = Ember::Template.content_from_block(@status_template, name, message, state).join
      else
        element = Hpricot::Elem.new('span', {'class' => state}, [Hpricot::Text.new(message)])
      end
      
      Hpricot::Elem.new('span', {
        'data-new-text' => new_text,
        'data-valid-text' => valid_text,
        'data-invalid-text' => invalid_text,
        'data-handles' => handles,
        'class' => 'yodel-field-status'
      }, [Hpricot::Text.new(element)])
    end
    
    def define_callback_function(name, parameter, block)
      Ember::Template.wrap_content_block(block) do |content|
        function_name = "#{@id}_#{name}"
        instance_variable_set("@#{name}_function", function_name)
        Hpricot::Elem.new('script', {}, [
          Hpricot::Text.new("#{function_name} = function(#{parameter}){"),
          Hpricot::Text.new(content.join),
          Hpricot::Text.new("}"),
        ])
      end
    end
    
    def build_element(tag, params, content=[])
      content = [content] unless content.respond_to?(:to_a)
      content = content.to_a.collect {|item| item.is_a?(String) ? Hpricot::Text.new(item): item}
      Hpricot::Elem.new(tag.to_s, params, content)
    end
    
    def condition(name, value, options, multiple=false)
      options = [options] unless options.respond_to?(:to_a) && !options.is_a?(BSON::ObjectId)
      {value: options.first}.tap do |attributes|
        if multiple
          attributes[name] = name if value.to_a.include?(options.first)
        else
          attributes[name] = name if options.to_a.include?(value)
        end
      end
    end
    
    def build_select(current_value, values, options={})
      show_blank = options[:show_blank]
      blank_text = options[:blank_text]
      group_by = options[:group_by]
      name_field = options[:name_field]
      value_field = options[:value_field]
      
      group_by_field = group_by.is_a?(Hash) ? group_by.keys.first : group_by
      current_value = current_value.map(&:to_s) if options[:multiple]
            
      if group_by_field
        select_options = Hash.new {|hash, key| hash[key] = []}
      else
        select_options = []
      end
      
      values.each do |value|
        if name_field && value_field
          option_name = value.send(name_field).to_s
          option_value = value.send(value_field).to_s
        else
          option_name = option_value = value.to_s
        end
        
        element = build_element(:option, condition('selected', current_value, option_value, options[:multiple]), option_name)
        
        if group_by_field
          key = value.send(group_by_field).to_s
          select_options[key] << element
        else
          select_options << element
        end
      end
      
      if group_by_field
        select_options = group_by[group_by_field].collect do |group_value, group_name|
          build_element(:optgroup, {label: group_name}, select_options[group_value])
        end
      end
      
      if show_blank
        blank_text = blank_text || 'Other'
        select_options.unshift(build_element(:option, condition('selected', current_value.to_s, ''), blank_text))
      end
      
      attributes = {}
      attributes[:multiple] = 'multiple' if options[:multiple]
      build_element(:select, attributes, select_options)
    end
end
