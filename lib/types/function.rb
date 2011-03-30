class Function < String
  class << self
    undef search_terms_set
  end
  
  def self.delay_load?
    true
  end
  
  def self.to_mongo(record, field, value)
    nil
  end
  
  def self.from_mongo(record, field, value)
    if value != field.default
      value
    else
      record.instance_eval(field.fn.to_s)
    end
  end
  
  def self.to_json(record, field, value)
    from_mongo(record, field, value)
  end
  
  def self.from_json(record, field, value)
    nil
  end
  
  def self.to_html_field(record, field, value)
    nil
  end
  
  def self.from_html_field(record, field, value)
    nil
  end
end
