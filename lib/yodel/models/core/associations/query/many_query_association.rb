module Yodel
  class ManyQueryAssociation < Association
    include Yodel::QueryAssociation
    include Yodel::ManyAssociation
  end
end
