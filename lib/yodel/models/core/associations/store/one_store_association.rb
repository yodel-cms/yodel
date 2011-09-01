class OneStoreAssociation < Association
  include StoreAssociation
  include OneAssociation
  
  def default_input_type
    :store_one
  end
  
  def untypecast(value, record)
    value.respond_to?(:id) ? value.id : nil
  end
end

Field::TYPES['one_store'] = OneStoreAssociation
