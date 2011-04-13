module Yodel
  class SiteRecord < Yodel::MongoRecord
    extend Yodel::SiteModel
    attr_reader :site
    
    def initialize(site, values={})
      @site = site
      super(values)
    end
    
    def site_id;  @values['_site_id']; end

    def default_values
      super.merge({'_site_id' => site.id})
    end
    
    def inspect_hash
      {site_id: site_id}.merge(super)
    end
    
    def perform_reload(id)
      load_mongo_document(_id: id)
    end
    
    def reload
      _site = site
      document = super
      initialize(_site, document)
    end
  end
end
