class Deploy
  def initialize
    @application = Application.new
    @site_id = ARGV.shift
  end
  
  def deploy_site
    puts "A site ID must be supplied as the last parameter to deploy" and return if @site_id.blank?
    site = Site.where(_id: BSON::ObjectId.from_string(@site_id)).first
    puts "Site could not be found" and return if site.nil?
    
    # read site.yml and update db record
    site.reload_from_site_yaml
    
    # remove "bad" domain names
    site.domains.reject! do |domain|
      domain =~ /\.yodel$/ || domain =~ /localhost/ || domain =~ /^(127|0|10)\./
    end
    
    # link public directories so a fronting web server can serve public assets easily
    site.domains.each do |domain|
      FileUtils.ln_s(site.public_directory, File.join(Yodel.config.public_directory, domain))
    end
    
    # migrate (taking the site live)
    Migration.run_migrations(site)
  end
end
