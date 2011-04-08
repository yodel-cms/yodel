class Date
  def to_json(*a)
    "new Date(#{year}, #{month}, #{day})".to_json(*a)
  end
end
