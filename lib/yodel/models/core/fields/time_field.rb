class TimeField < Field
  def default_input_type
    :datetime
  end
  
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
    return nil unless value.present? && (value.is_a?(String) || value.is_a?(Hash))
    if value.is_a?(Hash)
      return nil unless ['year', 'month', 'day', 'hour', 'min'].all? {|field| value.key?(field)}
      sec = value['sec'] || 0
      Time.new(value['year'], value['month'], value['day'], value['hour'], value['min'], sec).utc
    else
      Time.parse(value).utc
    end
  end
end

Field::TYPES['time'] = TimeField
