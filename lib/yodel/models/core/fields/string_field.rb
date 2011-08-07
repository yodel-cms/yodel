class StringField < Field
  def search_terms_set(record)
    record.get(name).to_s.gsub(/\W+/, ' ').split
  end

  def untypecast(value, record)
    value.nil? ? nil : value.to_s
  end

  def from_json(value, record)
    value.to_s
  end
end
