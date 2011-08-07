class SiteRecord < MongoRecord
  extend SiteModel
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
  
  def perform_reload(params)
    document = load_mongo_document(_id: params[:id])
    initialize(params[:site], document)
  end
  
  def prepare_reload_params
    super.tap {|vals| vals[:site] = site}
  end
end
