class Reference
  def self.from_mongo(record, field, value)
    return nil if value.nil?
    model = record.site.model(record.all_fields[field].try(:fetch, 'to', nil))
    return nil if model.nil?
    model.find(value)
  end
  
  def self.to_mongo(record, field, value)
    return nil if value.nil?
    value.id
  end
  
  def self.from_json(record, field, value)
    return nil if value.nil?
    model = record.site.model(record.all_fields[field].try(:fetch, 'to', nil))
    return nil if model.nil?
    record = model.find(value)
    record.try(:id)
  end
  
  def self.to_json(record, field, value)
    value.to_s
  end
  
  def self.from_html_field(record, field, value)
    from_json(record, field, value)
  end
  
  def self.to_html_field(record, field, value)
    field_options = record.all_fields[field]
    return nil if field_options.nil?
    
    model = record.site.model(field_options['to'])
    return nil if model.nil?
    value = value.to_s
    
    select_options = model.all.collect do |record|
      "<option value='#{record.id}' #{'selected' if record.id.to_s == value}>#{record.name}</option>"
    end
    
    unless field_options['required'] == true
      select_options.unshift("<option value='' #{'selected' if value.nil?}>None</option>")
    end
    
    "<select name='#{field}'>#{select_options.join('')}</select>"
  end
end
