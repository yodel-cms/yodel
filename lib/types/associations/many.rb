class Many < Array
  # FIXME: currently implements a to_many relationship by doing a lookup
  # we also need to support many ids stored within the record
  
  def self.uncacheable?
    true
  end
  
  def self.from_mongo(record, field, value)
    model = record.site.model(field.of)
    fkey  = field.foreign_key || record.model.name.underscore
    model.where(fkey => record.id).all
  end
  
  def self.to_mongo(record, field, value)
    model = record.site.model(field.of)
    fkey  = field.foreign_key || record.model.name.underscore
    
    value.each do |record|
      record.set_field(fkey, record)
      record.save
    end
    
    []
  end
  
  def self.from_json(record, field, value)
    []
  end
  
  def self.to_json(record, field, value)
    from_mongo(record, field, value).collect(&:id).collect(&:to_s)
  end
  
  def self.from_html_field(record, field, value)
    []
  end
  
  def self.to_html_field(record, field, value)
    raise "unimplemented"
  end
end
