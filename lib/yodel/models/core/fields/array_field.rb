module Yodel
  class ArrayField < Field
    # TODO: validate should defer to @element_type over each element
    def initialize(name, options={})
      @element_type = Field.from_options(name, 'type' => options['of'].to_s.singularize) if options['of']
      super
    end
    
    def json_action(action, value, record)
      array = record.get_raw(name)
      value = process(value, record, :from_json)
      value = [value] unless value.is_a?(Array)
      
      case action
      when 'set'
        array = value
      when 'add'
        array += value
      when 'add_unique'
        array |= value
      when 'remove'
        array -= value
      when 'clear'
        array = []
      end
      
      record.set_raw(name, array)
    end
  
    def typecast(value, record)
      value = [] unless value.is_a?(Array)
      Yodel::ChangeSensitiveArray.new(record, name, process(value, record, :typecast))
    end
    
    def untypecast(value, record)
      return [] if value.blank?
      process(value.to_a, record, :untypecast)
    end
    
    def from_json(value, record)
      return [] if value.blank?
      process(value.to_a, record, :from_json)
    end
    
    
    private
      def process(values, record, method)
        return values if @element_type.nil?
        if values.is_a?(Array)
          values.collect {|element| @element_type.send(method, element, record)}
        else
          @element_type.send(method, values, record)
        end
      end
  end
end
