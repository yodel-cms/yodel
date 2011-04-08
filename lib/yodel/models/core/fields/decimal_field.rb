module Yodel
  class DecimalField < Field
    def typecast(value, record)
      BigDecimal.new(value.to_s)
    end
    
    def untypecast(value, record)
      value.to_s
    end
    
    def from_json(value, record)
      record.set_raw(name, value.to_s)
    end
  end
end
