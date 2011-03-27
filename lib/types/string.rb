class String
  def self.to_mongo(record, field, value)
    value.nil? ? nil : new(value)
  end
  
  def self.from_mongo(record, field, value)
    value.nil? ? nil : new(value)
  end
  
  def search_terms_set
    self.gsub(/\W+/, ' ').split
  end
  
  def self.from_json(record, field, value)
    value.nil? ? nil : new(value)
  end
  
  def self.to_json(record, field, value)
    value.nil? ? nil : new(value)
  end
  
  def self.from_html_field(record, field, value)
    value.nil? ? nil : new(value)
  end
  
  def self.to_html_field(record, field, value)
    "<input type='text' name='#{field}' value='#{value}'>"
  end
end
