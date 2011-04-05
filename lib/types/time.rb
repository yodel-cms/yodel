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
  
  def to_json(*a)
    "new Date(#{year}, #{month}, #{day}, #{hour}, #{minute}, #{second})".to_json(*a)
  end
  
  def self.from_json(record, field, value, action)
    Time.new(value['year'], value['month'], value['day'], value['hour'], value['min'], value['sec']).utc
  end
end
