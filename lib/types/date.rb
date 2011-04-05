class Date
  extend YodelTypeInterface
  
  def self.to_mongo(record, field, value)
    return nil if value.blank?
    date = value.is_a?(Date) || value.is_a?(Time) ? value : Date.parse(value.to_s)
    Time.utc(date.year, date.month, date.day)
  end

  def self.from_mongo(record, field, value)
    value.to_date if value.present?
  end
  
  def to_json(*a)
    "new Date(#{year}, #{month}, #{day})".to_json(*a)
  end
  
  def self.from_json(record, field, value, action)
    Time.new(value['year'], value['month'], value['day'])
  end
end
