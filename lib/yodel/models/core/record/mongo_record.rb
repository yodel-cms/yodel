module Yodel
  class MongoRecord < AbstractRecord
    extend Yodel::MongoModel
    
    def fields
      self.class.fields
    end
    
    def collection
      self.class.collection
    end
    
    def id
      @values['_id']
    end

    def default_values
      super.merge({'_id' => Yodel::PrimaryKeyFactory.pk})
    end
    
    def inspect_hash
      {id: id}.merge(super)
    end
  
    def perform_save
      id = collection.save(@values, safe: true)
    rescue
      false
    end
  
    def perform_destroy
      result = collection.remove(_id: @values['_id'])
    rescue
      false
    end
    
    def perform_reload(id)
      initialize(load_mongo_document(_id: id))
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
      raise Yodel::DestroyedRecord if destroyed?
      raise Yodel::UnknownField, "Unknown field <#{name}>" unless field?(name)
      return false if new?
      
      increment_field = field(name)
      raise Yodel::InvalidField, "Field #{name} is not numeric" unless increment_field.numeric?
      
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
end
