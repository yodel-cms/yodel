module BSON
  class ObjectId
    def to_json(*a)
      to_s.to_json(*a)
    end
  
    def self.from_json(record, field, value, action)
      BSON::ObjectId.from_string(value)
    end
  end
end
