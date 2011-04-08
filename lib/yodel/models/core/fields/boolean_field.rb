module Yodel
  class BooleanField < Field
    def json_action(action, value, record)
      case action
      when 'set'
        record.set_raw(name, !!value)
      when 'toggle'
        record.set_raw(name, !record.get(name))
      end
    end
  
    def from_json(value, record)
      record.set_raw(name, !!value)
    end
  end
end
