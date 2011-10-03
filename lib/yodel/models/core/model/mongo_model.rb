require './model/abstract_model'

module MongoModel
  include AbstractModel
  
  def scoped(scope={})
    Query.new(self, nil, collection, scope)
  end
  
  def load(values)
    new(values)
  end
  
  def collection(*name)
    if name.size == 1
      @collection = Yodel.db.collection(name.first, pk: PrimaryKeyFactory)
    else
      @collection
    end
  end
end
