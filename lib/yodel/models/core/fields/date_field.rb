module Yodel
  class DateField < Field
    def typecast(value, record)
      value.blank? ? nil : value.to_date
    end
    
    def untypecast(value, record)
      value.blank? ? nil : Time.utc(value.year, value.month, value.day)
    end
    
    def from_json(value, record)
      # FIXME: ensure all required values exist in the value hash
      time = Time.new(value['year'], value['month'], value['day'])
      record.set_raw(name, time)
    end
  end
end
