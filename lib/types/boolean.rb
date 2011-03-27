class Boolean
  extend YodelTypeInterface
  
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
    options = {type: 'checkbox', name: field.name}
    
    if value.nil? && !field.default.nil?
      value = field.default
    end
    
    options[:checked] = 'checked' if !!value
    Hpricot::Elem.new('input', options)
  end
end
