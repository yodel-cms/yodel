module Yodel
  class IntegerField < Field
    def numeric?
      true
    end
    
    def json_action(action, value, record)
      case action
      when 'set'
        record.set_raw(name, value.to_i)
      when 'increment'
        record.increment!(name, value.to_i)
      end
      record.changed!(name)
    end
    
    def untypecast(value, record)
      value.to_i
    end
    
    def from_json(value, record)
      value.to_i
    end
  end
end
