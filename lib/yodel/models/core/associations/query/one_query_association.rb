module Yodel
  class OneQueryAssociation < Association
    include Yodel::QueryAssociation
    include Yodel::OneAssociation
    
    def untypecast(value, record)
      nil
    end
  end
end
