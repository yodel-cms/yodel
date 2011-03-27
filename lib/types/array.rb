class Array
  extend ::YodelTypeInterface
  
  def self.mutable?
    true
  end
  
  def self.from_html_field(record, field, value)
    value.nil? ? [] : new(value.split(',').map(&:strip).reject(&:blank?).uniq)
  end
  
  def self.to_html_field(record, field, value)
    Hpricot::Elem.new('input', type: 'text', name: field.name, value: value.try(:join, ', '))
  end
end
