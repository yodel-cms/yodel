class Boolean
  def self.to_mongo(record, field, value)
    !!value
  end

  def self.from_mongo(record, field, value)
    value.nil? ? nil : !!value
  end
  
  def self.from_json(record, field, value)
    raise "unimplemented"
  end
  
  def self.to_json(record, field, value)
    !!value
  end
end
