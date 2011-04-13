module Yodel
  class OneQueryAssociation < Association
    include Yodel::QueryAssociation
    include Yodel::OneAssociation
    
    def untypecast(value, record)
      return nil unless value.respond_to?(:set_meta)
      associate(value, nil, record)
      nil
    end
  end
end
