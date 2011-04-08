module Yodel
  class ArrayField < Field
    def json_action(action, value, record)
      array = record.get_raw(name)
      
      case action
      when 'set'
        array = value.to_a
      when 'add'
        array << value
      when 'remove'
        array.delete(value)
      end
      
      record.set_raw(name, array)
    end
  
    def typecast(value, record)
      ChangeSensitiveArray.new(record, name, value)
    end
    
    def untypecast(value, record)
      value.array
    end
    
    def from_json(value, record)
      record.set_raw(name, value.to_a)
    end
  end
end
