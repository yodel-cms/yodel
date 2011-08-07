class DecimalField < Field
  def numeric?
    true
  end
  
  def typecast(value, record)
    BigDecimal.new(value.to_s)
  end
  
  def untypecast(value, record)
    BigDecimal.new(value.to_s).to_s
  end
  
  def from_json(value, record)
    BigDecimal.new(value.to_s).to_s
  end
end
