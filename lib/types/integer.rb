class Integer
  extend YodelTypeInterface
  
  def self.to_mongo(record, field, value)
    value.nil? ? nil : value.to_i
  end
  
  def self.from_mongo(record, field, value)
    value.nil? ? nil : value.to_i
  end
  
  def self.from_json(record, field, value)
    value.nil? ? nil : value.to_i
  end
  
  def self.to_json(record, field, value)
    value.nil? ? nil : value.to_i
  end
  
  def self.from_html_field(record, field, value)
    value.nil? ? nil : value.to_i
  end
end
