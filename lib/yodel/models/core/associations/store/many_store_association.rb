module Yodel
  class ManyStoreAssociation < Association
    include Yodel::StoreAssociation
    include Yodel::ManyAssociation
  end
end
