class NooneGroup < Group
  def match_user_on_record?(user, record)
    false
  end
end
