class Many < Array
  def self.uncacheable?
    true
  end
  
  def self.from_mongo(record, field, value)
    options = record.all_fields[field]
    model = record.site.model(options['of'])
    fkey  = options['foreign_key'] || record.model.name.underscore
    
    model.where(fkey => record.id).all
  end
  
  def self.to_mongo(record, field, value)
    options = record.all_fields[field]
    model = record.site.model(options['of'])
    fkey  = options['foreign_key'] || record.model.name.underscore
    
    value.each do |record|
      record.set_field(fkey, record)
      record.save
    end
    
    []
  end
  
  def self.from_json(record, field, value)
    raise "unimplemented"
  end
  
  def self.to_json(record, field, value)
    raise "unimplemented"
  end
  
  def self.from_html_field(record, field, value)
    raise "unimplemented"
  end
  
  def self.to_html_field(record, field, value)
    raise "unimplemented"
  end
end
