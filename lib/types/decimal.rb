class Decimal < BigDecimal
  def self.to_mongo(record, field, value)
    value.to_s
  end

  def self.from_mongo(record, field, value)
    BigDecimal.new(value.to_s)
  end
  
  def self.from_json(record, field, value)
    new(decimal)
  end
  
  def self.to_json(record, field, value)
    value.to_s
  end
end
