class Text < String
  def self.to_html_field(record, field, value)
    "<textarea name='#{field}'>#{value}</textarea>"
  end
end
