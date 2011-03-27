class Array
  def self.mutable?
    true
  end
  
  def self.to_mongo(record, field, value)
    value.nil? ? nil : new(value)
  end
  
  def self.from_mongo(record, field, value)
    value.nil? ? nil : new(value)
  end
  
  def self.from_json(record, field, value)
    value.nil? ? nil : new(value)
  end
  
  def self.to_json(record, field, value)
    value.nil? ? nil : new(value)
  end
  
  def self.from_html_field(record, field, value)
    value.nil? ? [] : new(value.split(',').map(&:strip).reject(&:blank?).uniq)
  end
  
  def self.to_html_field(record, field, value)
    "<input type='text' name='#{field}' value='#{value.try(:join, ', ')}'>"
  end
end
