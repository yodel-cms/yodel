class Function < String
  undef_method(:search_terms_set)
  def self.uncacheable?
    true
  end
  
  def self.to_mongo(record, field, value)
    nil
  end
  
  def self.from_mongo(record, field, value)
    fn = record.all_fields[field].try(:fetch, 'fn', nil)
    record.instance_eval(fn.to_s)
  end
  
  def self.from_json(record, field, value)
    nil
  end
  
  def self.to_json(record, field, value)
    from_mongo(record, field, value)
  end
end
