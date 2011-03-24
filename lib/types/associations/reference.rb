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
    raise "unimplemented"
  end
  
  def self.to_json(record, field, value)
    value.to_s
  end
end
