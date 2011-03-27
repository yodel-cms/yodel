class Decimal < BigDecimal
  extend YodelTypeInterface
  
  def self.to_mongo(record, field, value)
    value.nil? ? nil : BigDecimal.new(value.to_s).to_s
  end

  def self.from_mongo(record, field, value)
    value.nil? ? nil : BigDecimal.new(value.to_s)
  end
  
  def self.from_json(record, field, value)
    value.nil? ? nil : BigDecimal.new(value.to_s)
  end
  
  def self.to_json(record, field, value)
    value.nil? ? nil : BigDecimal.new(value.to_s).to_s
  end
  
  def self.from_html_field(record, field, value)
    value.nil? ? nil : BigDecimal.new(value.to_s)
  end  
end
