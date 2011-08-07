class TimeField < Field
  def before_create(record)
    return unless name == 'created_at' || name == 'updated_at'
    record.set(name, Time.now.utc)
  end

  def before_update(record)
    return unless name == 'updated_at'
    record.set(name, Time.now.utc)
  end
  
  def typecast(value, record)
    value.nil? ? nil : Time.at(value)
  end
  
  def untypecast(value, record)
    value.blank? ? nil : Time.at(value.to_i).utc
  end
  
  def from_json(value, record)
    nil unless ['year', 'month', 'day', 'hour', 'min', 'sec'].all? {|field| value.key?(field)}
    Time.new(value['year'], value['month'], value['day'], value['hour'], value['min'], value['sec']).utc
  end
end
