class Group < Record
  def match_user_on_record?(user, record)
    return false if user.nil?
    user.values['groups'].include? id
  end
  
  def permitted?(user, record)
    match_user_on_record?(user, record) || parent.try(:match_user_on_record?, user, record)
  end
end
