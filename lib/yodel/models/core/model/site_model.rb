module Yodel
  module SiteModel
    include Yodel::MongoModel
    
    def scoped_for(site, scope={})
      scoped(site, self, scope.merge({_site_id: site.id}))
    end
    
    def scoped(site, constructor, scope={})
      Yodel::Query.new(constructor, site, collection, scope)
    end
    
    def scoped_with_constructor(site, constructor, scope={})
      scoped(site, constructor, scope.merge({_site_id: site.id}))
    end
    
    def load(site, values)
      new(site, values)
    end
  end
end