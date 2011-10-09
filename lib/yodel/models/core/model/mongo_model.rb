require './model/abstract_model'

module MongoModel
  include AbstractModel
  extend Forwardable
  def_delegators :scoped, :where, :limit, :skip, :sort, :count,
                          :last, :first, :all, :paginate, :find,
                          :find!, :exists?, :exist?, :find_each
  
  def scoped(scope={})
    Query.new(self, nil, collection, scope)
  end
  
  def load(values)
    new(values, false)
  end
  
  def collection(*name)
    if name.size == 1
      @collection = Yodel.db.collection(name.first, pk: PrimaryKeyFactory)
    else
      @collection
    end
  end
end
