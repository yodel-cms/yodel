module Yodel
  class ManyQueryAssociation < Association
    include Yodel::QueryAssociation
    include Yodel::ManyAssociation
    
    def untypecast(value, record)
      nil
    end
  end
end
