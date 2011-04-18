module Yodel
  class FormBuilder
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
    
    
    def field(name, options={}, &block)
      name = @prefix ? "#{@prefix}[][#{name}]" : name.to_s
      field = @record.field(name)
      value = @record.get(name)
      type = options.delete(:as) || field.default_input_type
      
      case type
      when :text
        element = Hpricot::Elem.new('input', {:type => 'text', :value => value})
      when :password
        element = Hpricot::Elem.new('input', {:type => 'password', :value => value})
      when :hidden
        element = Hpricot::Elem.new('input', {:type => 'hidden', :value => value})
      when :text_area
        element = Hpricot::Elem.new('textarea', {}, [Hpricot::Text.new(value)])
      when :radio
        true_button   = Hpricot::Elem.new('input', {:type => 'radio', :name => name, :value => 'true'})
        false_button  = Hpricot::Elem.new('input', {:type => 'radio', :name => name, :value => 'true'})
        true_text     = Hpricot::Text.new(options.delete(:true) || 'Yes')
        false_text    = Hpricot::Text.new(options.delete(:false) || 'No')
        element = Hpricot::Elem.new('span', {}, [true_text, true_button, false_text, false_button])        
        if !!value
          true_button.set_attribute('checked', 'checked')
        else
          false_button.set_attribute('checked', 'checked')
        end
      when :embedded
        value.each do |document|
          self.class.new(document, {embedded_record: field, prefix: name, id: @id}, &block).render
        end
        
        if options.delete(:blank_record)
          self.class.new(value.new, {embedded_record: field, blank_record: true, prefix: name, id: @id}, &block).render
        end
      end
      
      element.tap do |element|
        element.set_attribute(:id, name)
        element.set_attribute(:name, name)
        element.set_attribute(:placeholder, field.placeholder || '')
        element.set_attribute('data-field', name)
        options.each do |name, value|
          element.set_attribute(name.to_s, value)
        end
      end
    end
    
    
    def label(name, text=nil, options={})
      text ||= name.humanize
      Hpricot::Elem.new('label', {:for => name.to_s}, [Hpricot::Text.new(text)])
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
      
      if @record.errors.nil?
        state = 'new'
        message = new_text
      elsif handles.any? {|name| @record.errors.key?(name)}
        state = 'invalid'
        unless invalid_text.blank?
          message = invalid_text
        else
          message = handles.collect {|name| @record.errors[name].collect(&:describe)}.flatten.join(', ')
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
            Hpricot::Text.new("function #{function_name}(#{parameter}){"),
            Hpricot::Text.new(content.join),
            Hpricot::Text.new("}"),
          ])
        end
      end
  end
end
