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
    return nil unless value.is_a?(Date)
    {year: value.year, month: value.month, day: value.day}
  end
  
  def self.from_json(record, field, value)
    return nil if value.is_a?(nil)
    Time.new(value['year'], value['month'], value['day'])
  end
  
  def self.from_html_field(record, field, value)
    value.nil? ? nil : Date.parse(value).to_time
  end
  
  def self.to_html_field(record, field, value)
    "<input type='text' name='#{field}' value='#{value}'>"
  end
end
