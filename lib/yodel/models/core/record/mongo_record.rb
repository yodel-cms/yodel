require './record/abstract_record'
require './model/mongo_model'

class MongoRecord < AbstractRecord
  extend MongoModel
  
  def fields
    self.class.fields
  end
  
  def collection
    self.class.collection
  end
  
  def id
    @values['_id']
  end
  
  def set_id(new_id)
    @values['_id'] = new_id
  end

  def default_values
    super.merge({'_id' => PrimaryKeyFactory.pk})
  end
  
  def inspect_hash
    {id: id}.merge(super)
  end

  def perform_save
    id = collection.save(@values, safe: true)
  rescue
    # TODO: write Yodel.db.get_last_error to the log or as a warning to the site
    false
  end

  def perform_destroy
    result = collection.remove(_id: @values['_id'])
  rescue
    false
  end
  
  def perform_reload(params)
    document = load_mongo_document(_id: params[:id])
    initialize(document, false)
  end

  def load_mongo_document(scope)
    collection.find_one(scope)
  end

  def load_from_mongo(scope)
    @values = load_mongo_document(scope)
  end
  
  def increment!(name, value=1, conditions={})
    name = name.to_s
    
    # preconditions
    raise DestroyedRecord if destroyed?
    raise UnknownField, "Unknown field <#{name}>" unless field?(name)
    return false if new?
    
    increment_field = field(name)
    raise InvalidField, "Field #{name} is not numeric" unless increment_field.numeric?
    
    # atomic increment (amount can be negative)
    conditions = {_id: id}.merge(Plucky::CriteriaHash.new(conditions).to_hash)
    result = collection.update(conditions, {'$inc' => {name => value}}, safe: true)
    succeeded = successful_result?(result)
    
    # update the object cache, and indicate if the update was successful
    new_value = (get(name) || 0) + value
    @values[name] = @typecast[name] = new_value if succeeded
    succeeded
  end
  
  private
    def successful_result?(result)
      result['n'] != 0
    end
end
