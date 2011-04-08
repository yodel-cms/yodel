module Yodel
  class TimeField < Field
    def typecast(value, record)
      value.nil? ? nil : Time.at(value)
    end
    
    def untypecast(value, record)
      value.blank? ? nil : Time.at(value.to_i).utc
    end
    
    def from_json(value, record)
      # FIXME: ensure all required values exist in the value hash
      time = Time.new(value['year'], value['month'], value['day'],
                      value['hour'], value['min'], value['sec']).utc
      record.set_raw(name, time)
    end
  end
end
