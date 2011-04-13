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
    value = from_mongo(record, field, value)
    
    if value.is_a? Array
      # FIXME: don't assume all values are records; only set to id if the value /is/ a record
      if value.first.is_a? Yodel::Record
        value = value.collect(&:id).collect(&:to_s)
      end
    elsif value.is_a? Yodel::Record
      value = value.id.to_s
    end
    
    value
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
