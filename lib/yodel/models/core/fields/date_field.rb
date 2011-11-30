class DateField < Field
  def default_input_type
    :date
  end
  
  def before_create(record)
    return unless name == 'created_at' || name == 'updated_at'
    record.set(name, Time.now.utc.to_date)
  end

  def before_update(record)
    return unless name == 'updated_at'
    record.set(name, Time.now.utc.to_date)
  end
  
  def typecast(value, record)
    value.blank? ? nil : value.to_date
  end
  
  def untypecast(value, record)
    value.blank? ? nil : Time.utc(value.year, value.month, value.day)
  end
  
  def from_json(value, record)
    return nil unless value.present? && (value.is_a?(String) || value.is_a?(Hash))
    if value.is_a?(Hash)
      return nil unless ['year', 'month', 'day'].all? {|field| value.key?(field) && !value[field].blank?}
      Time.new(value['year'], value['month'], value['day'])
    else
      Time.parse(value)
    end
  end
end

Field::TYPES['date'] = DateField
