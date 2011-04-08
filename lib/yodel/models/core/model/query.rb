module Yodel
  class Query < Plucky::Query
    # construct a default scope for queries on a resource
    def initialize(constructor, site, collection, scope={})
      @site = site
      @constructor = constructor
      super(collection, scope)
    end
    
    # TODO: can search through identity map here to return cached records and avoid
    # an object creation step. Also cache any new records, so they can be matched
    # by single lookups in the future as well.
    def all(opts={})
      super.collect {|values| @constructor.load(@site, values)}
    end

    # TODO: extract this out to a collection sub class; yodel collection subclass
    # will override 'find' itself, so it doesn't need to be done here

    # override find_one to find objects via an identity hash
    def find_one(opts={})
      query = clone.update(opts)
      
      # construct the criteria hash, and remove the keys allowed by a cacheable lookup
      criteria_hash = query.criteria.to_hash
      id = criteria_hash[:_id]
      keys = criteria_hash.keys
      keys -= [:_id, :_site_id, :_model]
      
      # queries are cacheable if they are looking for a single ID
      cacheable = !id.nil? && id.is_a?(BSON::ObjectId) && keys.empty?
      
      # lookup the record in the cache
      if cacheable
        record = @site.cached_records[id]
        return record unless record.nil?
      end
      
      # lookup failed, so perform a query
      record = query.collection.find_one(criteria_hash, query.options.to_hash)
      if record
        record = @constructor.load(@site, record)
        @site.cached_records[id] = record if cacheable
      end
      
      record
    end
  end
end
