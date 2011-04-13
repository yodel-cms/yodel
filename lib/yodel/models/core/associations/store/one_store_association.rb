module Yodel
  class OneStoreAssociation < Association
    include Yodel::StoreAssociation
    include Yodel::OneAssociation
    
    def untypecast(value, record)
      value.respond_to?(:id) ? value.id : nil
    end    
  end
end
