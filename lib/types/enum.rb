class Enum
  def self.to_mongo(record, field, value)
    value.nil? ? nil : value.to_s
  end
  
  def self.from_mongo(record, field, value)
    value.nil? ? nil : value.to_s
  end
  
  def self.from_json(record, field, value)
    value.nil? ? nil : value.to_s
  end
  
  def self.to_json(record, field, value)
    value.nil? ? nil : value.to_s
  end
  
  def self.from_html_field(record, field, value)
    value.nil? ? nil : value.to_s
  end
  
  def self.to_html_field(record, field, value)
    field_options = record.all_fields[field]
    return nil if field_options.nil?
    value = value.to_s
    
    select_options = field_options['values'].collect do |enum_value|
      "<option value='#{enum_value}' #{'selected' if enum_value == value}>#{enum_value}</option>"
    end
    
    unless field_options['required'] == true
      select_options.unshift("<option value='' #{'selected' if value.nil?}>None</option>")
    end
    
    "<select name='#{field}'>#{select_options.join('')}</select>"
  end
end
