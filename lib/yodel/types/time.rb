class Time
  def to_json(*a)
    "new Date(#{year}, #{month}, #{day}, #{hour}, #{min}, #{sec})".to_json(*a)
  end
end
