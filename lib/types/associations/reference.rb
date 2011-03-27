class Reference
  extend YodelTypeInterface
  
  def self.from_mongo(record, field, value)
    return nil if value.nil?
    model = record.site.model(field.to)
    return nil if model.nil?
    model.find(value)
  end
  
  def self.to_mongo(record, field, value)
    return nil if value.nil?
    value.id
  end
  
  def self.from_json(record, field, value)
    return nil if value.nil?
    model = record.site.model(field.to)
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
    model = record.site.model(field.to)
    return nil if model.nil?
    if value.nil? && field.required && !field.default.nil?
      if field.eval
        value = record.instance_eval(field.default)
      else
        value = field.default
      end
    end
    value = value.to_s
    
    select_options = model.all.collect do |record|
      options = {value: record.id.to_s}
      options[:selected] = 'selected' if value == record.id.to_s
      Hpricot::Elem.new('option', options, [Hpricot::Text.new(record.name)])
    end
    
    unless field.required
      options = {value: ''}
      options[:selected] = 'selected' if value == ''
      select_options.unshift(Hpricot::Elem.new('option', options, [Hpricot::Text.new('None')]))
    end
    
    Hpricot::Elem.new('select', {name: field.name}, select_options)
  end
end
