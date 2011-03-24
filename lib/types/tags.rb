class Tags < Array
  def search_terms_set
    self
  end
  
  def self.from_json(record, field, value)
    new(value.split(',').map(&:strip).reject(&:blank?).uniq)
  end
  
  def to_json(record, field, value)
    to_s
  end
  
  def to_s
    self.join(', ')
  end
  
  def self.to_mongo(record, field, value)
    from_mongo(record, field, value)
  end

  def self.from_mongo(record, field, value)
    if value.is_a?(String)
      Tags.from_json(value)
    elsif value.nil?
      Tags.new
    else
      Tags.new(value)
    end
  end
end
