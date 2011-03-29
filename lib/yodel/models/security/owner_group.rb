module Yodel
  class OwnerGroup < Group
    def match_user_on_record?(user, record)
      user == record.owner
    rescue
      false
    end
  end
end
