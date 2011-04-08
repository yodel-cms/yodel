module Yodel
  class MongoModel < AbstractRecord
    # ----------------------------------------
    # Record implementation
    # ----------------------------------------
    attr_reader :site
    
    def initialize(site, values={})
      @site = site
      super(values)
    end
    
    def site_id;  @values['_site_id']; end
    def id;       @values['_id']; end

    def default_values
      { '_id' => Yodel::PrimaryKeyFactory.pk,
        '_site_id' => site.id
      }.merge(super)
    end
    
    def inspect_hash
      {id: id, site_id: site_id}.merge(super)
    end
  
    def perform_save
      # FIXME: safe: true, and handle failed result
      self.class.collection.save(@values)
    end
  
    def perform_destroy
      self.class.collection.remove(_id: @values['_id'])
    end
    
    def perform_reload(id)
      initialize(load_mongo_document(_id: id), site)
    end
  
    def load_mongo_document(scope)
      self.class.collection.find_one(scope)
    end
  
    def load_from_mongo(scope)
      @values = load_mongo_document(scope)
    end
    
    def increment!(field, value=1, conditions={})
      field = field.to_s
      
      # preconditions
      raise Yodel::DestroyedRecord if destroyed?
      raise NameError unless field?(field)
      return false if new?
      # FIXME: add check to ensure field is a numeric type
      
      # atomic increment (amount can be negative)
      conditions = {_id: id}.merge(Plucky::CriteriaHash.new(conditions).to_hash)
      result = self.class.collection.update(conditions, {'$inc' => {field => value}}, safe: true)
      succeeded = result['n'] != 0
      
      # update the object cache, and indicate if the update was successful
      @values[field] += value if succeeded # FIXME: will fail if @values[field] was nil
      @typecast[field] = @values[field] if succeeded # FIXME: should pull the value through from_mongo
      succeeded
    end
    
    
    # ----------------------------------------
    # Model
    # ----------------------------------------
    include Yodel::AbstractModel
    
    def self.scoped_for(site, scope={})
      scoped(site, scope.merge({_site_id: site.id}))
    end
    
    def self.scoped(site, scope={})
      Yodel::Query.new(self, site, collection, scope)
    end
    
    def self.load(site, values)
      new(site, values)
    end
    
    def self.collection(*name)
      if name.size == 1
        @collection = Yodel.config.db_connection.collection(name, pk: Yodel::PrimaryKeyFactory)
      else
        @collection
      end
    end    
  end
end
