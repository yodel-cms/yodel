module Yodel
  class FormBuilder
    def initialize(record, options={}, &block)
      @record = record
      @options = options
      @block = block
      
      @url = options.delete(:url)
      @method = options.delete(:method)
      @embedded_record = options.delete(:embedded_record)
      @blank_record = options.delete(:blank_record)
      
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
        @record[name]
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
          self.class.new(document, {base_record: @base_record, embedded_record: field}, &block).render
        end
        
        if options[:blank_record]
          self.class.new({}, {base_record: @base_record, embedded_record: field, blank_record: true}, &block).render
        end
      else
        Object.module_eval(field.type).to_html_field(@record, field, value).to_s
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
          Hpricot::Elem.new('form', {url: @url, method: @method}, [Hpricot::Text.new(content.join)])
        end
      end
    end
  end
end
