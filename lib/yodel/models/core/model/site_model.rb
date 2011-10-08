require './model/mongo_model'

module SiteModel
  include MongoModel
  
  def scoped_for(site, scope={})
    scoped(site, self, scope.merge({_site_id: site.id}))
  end
  
  def scoped(site, constructor, scope={})
    Query.new(constructor, site, collection, scope)
  end
  
  def load(site, values)
    new(site, values).tap do |record|
      record.new = false
    end
  end
end
