class OneQueryAssociation < Association
  include QueryAssociation
  include OneAssociation
  
  def untypecast(value, record)
    nil
  end
end

Field::TYPES['one_query'] = OneQueryAssociation
