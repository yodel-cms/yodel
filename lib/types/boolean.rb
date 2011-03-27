class Boolean
  def self.to_mongo(record, field, value)
    value.nil? ? nil : !!value
  end

  def self.from_mongo(record, field, value)
    value.nil? ? nil : !!value
  end
  
  def self.from_json(record, field, value)
    value.nil? ? nil : !!value
  end
  
  def self.to_json(record, field, value)
    value.nil? ? nil : !!value
  end
  
  def self.from_html_field(record, field, value)
    value.nil? ? false : true
  end
  
  def self.to_html_field(record, field, value)
    "<input type='checkbox' name='#{field}' #{'checked' if value}>"
  end
end
