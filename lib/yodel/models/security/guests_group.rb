class GuestsGroup < Group
  def match_user_on_record?(user, record)
    true
  end
end
