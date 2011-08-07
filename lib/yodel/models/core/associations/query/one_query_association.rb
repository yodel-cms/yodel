class OneQueryAssociation < Association
  include QueryAssociation
  include OneAssociation
  
  def untypecast(value, record)
    nil
  end
end
