class Time
  extend YodelTypeInterface
  
  def self.to_mongo(record, field, value)
    return nil if value.blank?
    time = value.is_a?(Time) ? value : Time.parse(value.to_s)
    Time.at(time.to_i).utc
  end

  def self.from_mongo(record, field, value)
    Time.at(value)
  end
  
  def self.to_json(record, field, value)
    return nil unless value.is_a?(Time)
    {year: value.year, month: value.month, day: value.day, hour: value.hour, min: value.min, sec: value.sec}
  end
  
  def self.from_json(record, field, value)
    Time.new(value['year'], value['month'], value['day'], value['hour'], value['min'], value['sec']).utc
  end
  
  def self.from_html_field(record, field, value)
    value.nil? ? nil : DateTime.parse(value).to_time.utc
  end
end
