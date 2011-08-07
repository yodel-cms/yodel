class ManyQueryAssociation < Association
  include QueryAssociation
  include ManyAssociation
  
  def untypecast(value, record)
    nil
  end
end
