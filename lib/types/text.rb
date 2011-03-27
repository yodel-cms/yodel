class Text < String
  def self.to_html_field(record, field, value)
    Hpricot::Elem.new('textarea', {name: field.name}, [Hpricot::Text.new(value.to_s)])
  end
end
