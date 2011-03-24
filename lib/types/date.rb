class Date
  def self.to_mongo(record, field, value)
    return nil if value.blank?
    date = value.is_a?(Date) || value.is_a?(Time) ? value : Date.parse(value.to_s)
    Time.utc(date.year, date.month, date.day)
  end

  def self.from_mongo(record, field, value)
    value.to_date if value.present?
  end
  
  def self.to_json(record, field, value)
    raise "unimplemented"
  end
  
  def self.from_json(record, field, value)
    raise "unimplemented"
  end
end
