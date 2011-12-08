class Deploy
  def initialize
    @application = Application.new
    @site_id = ARGV.shift
  end
  
  def deploy_site
    puts "A site ID must be supplied as the last parameter to deploy" and return if @site_id.blank?
    site = Site.where(_id: BSON::ObjectId.from_string(@site_id)).first
    puts "Site could not be found" and return if site.nil?
    new_site = site.migrations.empty?
    
    # store the list of domains associated with this site; once the site has been reloaded from
    # the updated yaml file, deleted domains need to have their corresponding folders removed
    old_domains = site.domains.dup
    
    # read site.yml and update db record
    site.reload_from_site_yaml
    
    # FIXME: it's possible for one site to take control of another's domains at the moment;
    # process "should" be that the first site with a domain owns that domain. Only it can
    # add subdomains to it; yodelcms.com etc. is an exception to this.
    # remove "bad" domain names
    site.domains = site.remote_domains
    
    # link public directories so a fronting web server can serve public assets easily
    site.domains.each do |domain|
      path = File.join(Yodel.config.public_directory, domain)
      FileUtils.ln_s(site.public_directory, path) unless File.exists?(path)
    end
    
    # remove folders associated with deleted domains
    old_domains -= site.domains
    old_domains.each do |domain|
      path = File.join(Yodel.config.public_directory, domain)
      FileUtils.rm(path) if File.exists?(path)
    end
    
    # migrate (taking the site live)
    Migration.run_migrations(site)
    
    # reload layouts from disk
    Layout.reload_layouts(site)
    
    # the first time a site is created, all users with access to the site (1 at this stage
    # in most cases) are copied as administrators of the new site. As users are added and
    # removed, their corresponding administrator records are updated in the site.
    if new_site
      production_site = Site.where(name: 'yodel').first
      production_site.users.where(sites: site.id).all.each do |admin|
        user = site.users.new
        user.first_name = admin.name
        user.email = admin.email
        user.username = admin.email
        user.password = admin.password
        user.groups << site.groups['Developers']
        user.save

        # because of the before_create callback, we need to override
        # the salt and password manually by saving again
        user.password_salt = nil
        user.password = admin.password
        user.save_without_validation
      end
    end
  end
end
