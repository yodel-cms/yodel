module YodelTypeInterface
  def mutable?
    false
  end
  
  def delay_load?
    false
  end
  
  def to_mongo(record, field, value)
    value.nil? ? nil : new(value)
  end
  
  def from_mongo(record, field, value)
    value.nil? ? nil : new(value)
  end
  
  def from_json(record, field, value)
    value.nil? ? nil : new(value)
  end
  
  def to_json(record, field, value)
    value.nil? ? nil : new(value)
  end
  
  def from_html_field(record, field, value)
    value.nil? ? nil : new(value)
  end
  
  def to_html_field(record, field, value)
    placeholder = ''
    unless field.default.nil?
      if field.eval
        placeholder = field.instance_eval(field.default)
      else
        placeholder = field.default
      end
    end
    
    Hpricot::Elem.new('input', type: 'text', name: field.name, value: value.to_s, placeholder: placeholder.to_s)
  end  
end
