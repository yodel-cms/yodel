require 'fileutils'
require 'cgi'

# handles requests to the 'yodel' domain
class DevelopmentRuntime
  CREATE_SITE_PATH = /^\/create_site\/(?<name>.+)\.yodel$/
  
  def initialize(app)
    @app = app
  end
  
  def call(env)
    request = Rack::Request.new(env)
    return @app.call(env) unless env['yodel.site'].nil?

    # handle the create_site command
    if request.path =~ CREATE_SITE_PATH
      return create_site($1, request)
    end

    # runtime is the last middleware before the main yodel
    # request handler. domain not found exceptions are
    # raised from here and not from the site_detector
    # middleware so the public_assets middleware has a
    # chance to respond before the exception is raised.
    # runtime pages depend on this so assets are served.
    raise DomainNotFound.new(request.host, request.port)
  end
  
  def create_site(name, request)
    # create a new folder for the site
    site_dir = Yodel.config.sites_root.join(name)
    site_dir.mkpath
    
    # create the new site
    site = Site.new
    site.name = name
    site.root_directory = site_dir.realpath.to_s
    site.domains << "#{name}.yodel"
    
    # install the standard set of folders
    site_dir.join(Yodel::LAYOUTS_DIRECTORY_NAME).mkdir
    site_dir.join(Yodel::MIGRATIONS_DIRECTORY_NAME).mkdir
    site_dir.join(Yodel::PARTIALS_DIRECTORY_NAME).mkdir
    site_dir.join(Yodel::PUBLIC_DIRECTORY_NAME).mkdir
    site_dir.join(Yodel::ATTACHMENTS_DIRECTORY_NAME).mkdir
    
    # copy core yodel migrations
    yodel_migrations_dir = site_dir.join(Yodel::MIGRATIONS_DIRECTORY_NAME).join(Yodel::YODEL_MIGRATIONS_DIRECTORY_NAME)
    FileUtils.cp_r(File.join(File.dirname(__FILE__), '..', 'models', 'migrations'), yodel_migrations_dir)
    
    # copy extension migrations
    extension_migrations_dir = site_dir.join(Yodel::MIGRATIONS_DIRECTORY_NAME).join(Yodel::EXTENSION_MIGRATIONS_DIRECTORY_NAME)
    extension_migrations_dir.mkdir
    Yodel.config.extensions.each do |extension|
      FileUtils.cp_r(extension.migrations_dir, extension_migrations_dir.join(extension.name)) if extension.migrations_dir.exist?
      site.extensions << extension.name
    end
    
    # create a blank site migrations folder
    site_dir.join(Yodel::MIGRATIONS_DIRECTORY_NAME).join(Yodel::SITE_MIGRATIONS_DIRECTORY_NAME).mkdir
    
    # create the repository and perform the first commit
    if Yodel.config.owner_group != 0
      FileUtils.chown_R(Yodel.config.owner_user, Yodel.config.owner_group, site_dir.realpath.to_s)
    else
      FileUtils.chown_R(Yodel.config.owner_user, nil, site_dir.realpath.to_s)
    end
    repos = Git.init(site_dir.realpath.to_s)
    repos.config('user.name', Yodel.config.remote_name)
    repos.config('user.email', Yodel.config.remote_email)
    repos.add_remote('origin', "http://#{CGI.escape(Yodel.config.remote_email)}:#{CGI.escape(Yodel.config.remote_pass)}@#{Yodel.config.remote_host}/git/#{name}")
    repos.add([Yodel::LAYOUTS_DIRECTORY_NAME, Yodel::MIGRATIONS_DIRECTORY_NAME, Yodel::PARTIALS_DIRECTORY_NAME, Yodel::PUBLIC_DIRECTORY_NAME, Yodel::ATTACHMENTS_DIRECTORY_NAME])
    repos.commit_all('New yodel site')
    
    # save and initialise the site
    site.save
    Migration.run_migrations(site)
    
    # create a default admin user
    user = site.users.new
    user.first_name = Yodel.config.remote_name
    user.email = Yodel.config.remote_email
    user.username = Yodel.config.remote_email
    user.password = Yodel.config.remote_pass
    user.groups << site.groups['Developers']
    user.save
    
    # because of the before_create callback, we need to override
    # the salt and password manually by saving again
    user.password_salt = nil
    user.password = Yodel.config.remote_pass
    user.save_without_validation
    
    # redirect to the new site
    response = Rack::Response.new
    port = (request.port == 80 ? nil : request.port)
    response.redirect "http://#{name}.yodel#{':' if port}#{port}/admin/pages"
    response.finish
  end
end
