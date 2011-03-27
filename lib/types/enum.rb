class Enum < String
  class << self
    undef search_terms_set
  end
  
  def self.to_html_field(record, field, value)
    if value.nil? && !field.default.nil?
      value = field.default
    end
    value = value.to_s
    
    select_options = field.values.collect do |enum_value|
      options = {value: enum_value}
      options[:selected] = 'selected' if value == enum_value
      Hpricot::Elem.new('option', options, [Hpricot::Text.new(enum_value)])
    end
    
    unless field.required
      options = {value: ''}
      options[:selected] = 'selected' if value == ''
      select_options.unshift(Hpricot::Elem.new('option', options, [Hpricot::Text.new('None')]))
    end
    
    Hpricot::Elem.new('select', {name: field.name}, select_options)
  end
end
