class Time
  def to_json(*a)
    "new Date(#{year}, #{month}, #{day}, #{hour}, #{minute}, #{second})".to_json(*a)
  end
end
