module Yodel
  module OneAssociation
    def typecast(value, record)
      return default if value.blank?
      associated(value, record)
    end
    
    private
      def clear(store, record)
        unassociate(associated(store, record), store, record)
      end
  end
end
