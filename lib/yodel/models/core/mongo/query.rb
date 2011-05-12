module Yodel
  class Query < Plucky::Query
    attr_reader :constructor, :site
    
    # construct a default scope for queries on a resource
    def initialize(constructor, site, collection, scope={})
      @site = site
      @constructor = constructor
      super(collection, scope)
    end
    
    def distinct(key)
      record = collection.distinct(key, criteria.to_hash)
    end
    
    # TODO: we only cache queries where _id, _site_id, and model are present; _id on
    # its own is a strong enough restriction, so why can't we cache all queries with id?
    # the query may not match (extra restrictions), but for quries that do match, we
    # should save id-> recrd in cached_records
    # TODO: cache any new records, so they can be matched by single lookups in the future
    def all(opts={})
      if @site
        super.collect do |values|
          record = @site.cached_records[values['_id']]
          record ? record : @constructor.load(@site, values)
        end
      else
        super.collect {|values| @constructor.load(values)}
      end
    end

    # TODO: extract this out to a collection sub class; yodel collection subclass
    # will override 'find' itself, so it doesn't need to be done here

    # override find_one to find objects via an identity hash
    def find_one(opts={})
      unless @site
        document = super
        return nil if document.nil?
        @constructor.load(document)
      else
        query = clone.update(opts)
      
        # construct the criteria hash, and remove the keys allowed by a cacheable lookup
        criteria_hash = query.criteria.to_hash
        id = criteria_hash[:_id]
        keys = criteria_hash.keys
        keys -= [:_id, :_site_id, :model]
      
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
end
