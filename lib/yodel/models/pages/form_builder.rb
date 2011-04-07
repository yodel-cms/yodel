module Yodel
  class FormBuilder
    def initialize(record, options={}, &block)
      @record = record
      @options = options
      @block = block
      
      @action = options.delete(:action)
      @method = options.delete(:method) || 'post'
      @params = options.delete(:params) || {}
      @embedded_record = options.delete(:embedded_record)
      @blank_record = options.delete(:blank_record)
      @embedded_doc_name = options.delete(:embedded_doc_name)
      
      @base_record = options.delete(:base_record) || @record
    end
    
    def field_options(name)
      if @embedded_record
        field = @embedded_record.fields.detect {|field| field['name'] == name}
        return nil if field.nil?
        OpenStruct.new(field)
      else
        @record.field_options(name)
      end
    end
    
    def field_value(name)
      if @embedded_record
        @record.send(name)
      else
        @record.get_field(name)
      end
    end
    
    def field(name, options={}, &block)
      name = name.to_s
      field = field_options(name)
      value = field_value(name)
      
      if field.type == 'Embedded'
        value.each do |document|
          self.class.new(document, {base_record: @base_record, embedded_record: field, embedded_doc_name: name}, &block).render
        end
        
        if options[:blank_record]
          self.class.new(OpenStruct.new(site: @base_record.site), {base_record: @base_record, embedded_record: field, blank_record: true, embedded_doc_name: name}, &block).render
        end
      else
        if @embedded_doc_name
          field.name = "#{@embedded_doc_name}[][#{field.name}]"
        end
        element = Object.module_eval(field.type).to_html_field(@record, field, value)
        return nil if element.nil?
        element.set_attribute(:id, name)
        options.each do |name, value|
          element.set_attribute(name, value)
        end
        element
      end
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
          Hpricot::Elem.new('form', {action: @action, method: 'post'}.merge(@params), [
            Hpricot::Text.new(content.join),
            Hpricot::Elem.new('input', {type: 'hidden', name: '_method', value: @method})
          ])
        end
      end
    end
  end
end