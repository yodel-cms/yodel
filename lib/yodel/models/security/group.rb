module Yodel
  class Group < Record
    allowed_child_types self, Yodel::User
    multiple_roots
    
    key :name, String, required: true
    
    def icon
      '/admin/images/group_icon.png'
    end
  end
end
