class Site < MongoRecord
  attr_reader :cached_records, :cached_models
  GIT_REMOTE_NAME = 'yodel'
  
  collection :sites
  field :name, :string
  field :created_at, :time
  field :root_directory, :string
  field :remote_id, :string
  field :model_plural_names, :hash
  field :model_types, :hash
  field :extensions, :array
  field :migrations, :array
  field :options, :hash
  field :domains, :array
  one   :remote
  
  def initialize(values={}, new_record=true)
    super
    @cached_records = {}
    @cached_models  = {}
    
    # static models
    @models = Model.scoped_for(self)
    @cached_models['Model']   = @cached_models['models']    = @models
    @cached_models['Trigger'] = @cached_models['triggers']  = Trigger.scoped_for(self)
    @cached_models['Task']    = @cached_models['tasks']     = Task.scoped_for(self)
  end
    
  
  # ----------------------------------------
  # Accessors
  # ----------------------------------------
  # TODO: a better interface is site.options.name.option; site.options.pages.permalink_character
  def option(path)
    component, option = path.split('.')
    options[component].try(:fetch, option, nil).try(:fetch, 'value', nil)
  end
  
  def log
    @log ||= Log.new(self)
  end
  
  def yodel_site?
    name == 'yodel'
  end
  
  def regular_site?
    name != 'yodel'
  end
  
  def root_directory
    @root_directory ||= begin
      if regular_site?
        get('root_directory')
      elsif Yodel.env.production?
        Yodel.extensions['yodel_production_environment'].lib_dir
      else
        Yodel.extensions['yodel_development_environment'].lib_dir
      end
    end
  end
  
  def public_directory
    @public_dir ||= File.join(root_directory, Yodel::PUBLIC_DIRECTORY_NAME)
  end
  
  def public_directories
    @public_dirs ||= Yodel.config.public_directories + [public_directory]
  end
  
  def layouts_directory
    @layouts_dir ||= File.join(root_directory, Yodel::LAYOUTS_DIRECTORY_NAME)
  end
  
  def layout_directories
    @layout_dirs ||= Yodel.config.layout_directories + [layouts_directory]
  end
  
  def partials_directory
    @partials_dir ||= File.join(root_directory, Yodel::PARTIALS_DIRECTORY_NAME)
  end
  
  def migrations_directory
    @migrations_dir ||= File.join(root_directory, Yodel::MIGRATIONS_DIRECTORY_NAME)
  end
  
  def site_migrations_directory
    @site_migrations_dir ||= File.join(migrations_directory, Yodel::SITE_MIGRATIONS_DIRECTORY_NAME)
  end
  
  def extensions_migrations_directory
    @extensions_migrations_dir ||= File.join(migrations_directory, Yodel::EXTENSION_MIGRATIONS_DIRECTORY_NAME)
  end
  
  def yodel_migrations_directory
    @yodel_migrations_dir ||= File.join(migrations_directory, Yodel::YODEL_MIGRATIONS_DIRECTORY_NAME)
  end
  
  def attachments_directory
    @attachments_dir ||= File.join(root_directory, Yodel::ATTACHMENTS_DIRECTORY_NAME)
  end
  
  def site_yaml_path
    File.join(root_directory, Yodel::SITE_YML_FILE_NAME)
  end
  
  def local_domain
    domains.find {|domain| domain.end_with?('.yodel')}
  end
  
  def remote_domains
    domains.select do |domain|
      !domain.end_with?('.yodel') &&
      !domain.end_with?('.local') &&
      !domain.end_with?('.localhost') &&
      !domain.start_with?('192.168.') &&
      !domain.start_with?('10.') &&
      !domain.start_with?('127.') &&
      (!domain.start_with?('172.') || !(16..31).include?(domain.split('.')[1].to_i)) &&
      domain != '0.0.0.0' &&
      domain != '255.255.255.255' &&
      domain != 'localhost' &&
      domain != 'broadcasthost'
    end
  end
  
  def latest_revision
    Dir.chdir(root_directory) do
      `git log -n1 --pretty=format:"%H"`
    end
  end
  
  def latest_revision_date
    Dir.chdir(root_directory) do
      `git log -n1 --pretty=format:"%ai"`
    end
  end
  
  
  # ----------------------------------------
  # Life cycle
  # ----------------------------------------
  before_destroy :destroy_records
  def destroy_records
    Trigger.collection.remove(_site_id: id)
    LogEntry.collection.remove(_site_id: id)
    Record.collection.remove(_site_id: id)
    Model.collection.remove(_site_id: id)
    Task.collection.remove(_site_id: id)
  end
  
  after_destroy :destroy_directories
  def destroy_directories
    # root directory
    FileUtils.remove_entry_secure(root_directory) if File.directory?(root_directory)
    
    # domain symlinks in production
    if Yodel.env.production?
      domains.each do |domain|
        path = File.join(Yodel.config.public_directory, domain)
        FileUtils.remove_file(path, true) if File.symlink?(path)
      end
    end
  end
  
  after_save :update_site_yml
  def update_site_yml
    return unless Yodel.env.development?
    File.open(site_yaml_path, 'w') do |file|
      file.write(YAML.dump({
        name: name.to_s,
        extensions: extensions.to_a,
        domains: remote_domains.to_a,
        options: options.to_hash
      }))
    end
  end
  
  def reload_from_site_yaml
    update(YAML.load_file(site_yaml_path))
  end
  
  def self.clone(name, remote, remote_id, default_user)
    return 'No site name provided' if name.blank?
    return 'No remote provided' if remote.blank?
    return 'No remote site id provided' if remote_id.blank?
    return 'No default user provided' if default_user.blank?
    
    # determine where to clone from
    git_url = remote.git_url(remote_id)
    return 'Git URL could not be constructed' if git_url.blank?
    
    # find an unused site directory
    identifier = cleanse_name(name)
    site_dir = find_unused_site_dir(identifier)
    
    # clone the repos locally  
    Dir.chdir(Yodel.config.sites_root) do
      result = `#{Yodel.config.git_path} clone -o #{GIT_REMOTE_NAME} #{git_url} #{site_dir}`
      return "Git error: #{$1}" if result =~ /error: (.+)$/
    end
    
    # the attachments directory is in .gitignore
    Dir.mkdir(File.join(site_dir, Yodel::ATTACHMENTS_DIRECTORY_NAME))
    
    # when running as a daemon, the root user will own the cloned repos
    Dir.chdir(Yodel.config.sites_root) do
      return unless Yodel.config.owner_user
      if Yodel.config.owner_group != 0
        FileUtils.chown_R(Yodel.config.owner_user, Yodel.config.owner_group, site_dir)
      else
        FileUtils.chown_R(Yodel.config.owner_user, nil, site_dir)
      end
    end
    
    # create a new site from the cloned site.yml file
    site_yml = File.join(site_dir, Yodel::SITE_YML_FILE_NAME)
    return 'Site yml file was not cloned successfully' unless File.exist?(site_yml)
    new_site = Site.new(YAML.load_file(site_yml)).tap do |site|
      site.root_directory = File.dirname(site_yml)
    end
    
    # add the remote and a new default local domain
    new_site.domains.unshift(find_unused_domain(identifier))
    new_site.remote_id = remote_id
    new_site.remote = remote
    new_site.save
    
    # initialise the site
    Migration.run_migrations(new_site)
    create_default_user(new_site, default_user)
    return new_site
  end
  
  def self.create(name, default_user)
    return 'No site name provided' if name.blank?
    return 'No default user provided' if default_user.blank?
    
    # create a new folder for the site
    identifier = cleanse_name(name)
    site_dir = find_unused_site_dir(identifier)
    FileUtils.cp_r(File.join(File.dirname(__FILE__), 'site_template'), site_dir)
    
    # rename the gitignore file so it becomes active
    FileUtils.mv(File.join(site_dir, 'gitignore'), File.join(site_dir, '.gitignore'))

    # create the new site
    new_site = Site.new
    new_site.name = name
    new_site.root_directory = site_dir
    new_site.domains << find_unused_domain(identifier)

    # copy core yodel migrations
    FileUtils.cp_r(Yodel.config.yodel_migration_directory, new_site.yodel_migrations_directory)

    # copy extension migrations
    extension_migrations_dir = new_site.extensions_migrations_directory
    Yodel.config.extensions.each do |extension|
      if File.directory?(extension.migrations_dir)
        FileUtils.cp_r(extension.migrations_dir, File.join(extension_migrations_dir, extension.name))
      end
      new_site.extensions << extension.name
    end

    # create the repository and perform the first commit
    if Yodel.config.owner_user
      if Yodel.config.owner_group != 0
        FileUtils.chown_R(Yodel.config.owner_user, Yodel.config.owner_group, site_dir)
      else
        FileUtils.chown_R(Yodel.config.owner_user, nil, site_dir)
      end
    end
    
    Dir.chdir(site_dir) do
      `#{Yodel.config.git_path} init .`
      `#{Yodel.config.git_path} config 'user.name' '#{default_user.name.gsub("'", "\\\\'")}'`
      `#{Yodel.config.git_path} config 'user.email' '#{default_user.email.gsub("'", "\\\\'")}'`
      `#{Yodel.config.git_path} config 'http.postBuffer' #{200 * 1024 * 1024}`
      `#{Yodel.config.git_path} add .`
      `#{Yodel.config.git_path} commit -a -m 'New yodel site'`
    end

    # save and initialise the site
    new_site.save
    Migration.run_migrations(new_site)
    create_default_user(new_site, default_user)
    return new_site
  end
  
  class << self
    private
    def create_default_user(new_site, default_user)
      user = new_site.users.new
      user.first_name = default_user.name
      user.email = default_user.email
      user.username = default_user.email
      user.password = Password.hashed_password(nil, default_user.password)
      user.groups << new_site.groups['Developers']
      user.save

      # because of the before_create callback, we need to override
      # the salt and password manually by saving again, otherwise
      # user.password will be hashed twice
      user.password_salt = nil
      user.password = Password.hashed_password(nil, default_user.password)
      user.save_without_validation
    end

    def cleanse_name(name)
      name.downcase.gsub(/[^a-z0-9]+/, '-')
    end
    
    def find_unused_site_dir(name)
      site_dir = name
      counter = 0
      while File.exist?(File.join(Yodel.config.sites_root, site_dir))
        counter += 1
        site_dir = "#{name}-#{counter}"
      end
      File.join(Yodel.config.sites_root, site_dir)
    end
    
    def find_unused_domain(name)
      domain = "#{name}.yodel"
      counter = 0
      while Site.exists?(domains: domain)
        counter += 1
        domain = "#{name}-#{counter}.yodel"
      end
      domain
    end
  end
  
  
  # ----------------------------------------
  # Model Lookups
  # ----------------------------------------
  # Method missing is utilised to allows lookups of models by their plural name
  # directly on a site object. site.models is equivalent to site.model('Model')
  def method_missing(name, *args, &block)
    # attempt to find the model in the cached_models hash
    key = name.to_s
    model = @cached_models[key]
    return model unless model.nil?
    
    # otherwise perform a lookup
    model = model_by_plural_name(key)
    return super if model.nil?
    model
  end
  
  # Retrieve a model by its plural name ('models' as opposed to 'Model'). In general
  # use the method missing functionality of site since it checks the cached_models
  # hash before performing a lookup, whereas this method will always do a lookup.
  def model_by_plural_name(name)
    # ensure the site has a reference to a model by this name. get is required here
    # instead calling 'model_types' explicitly as that relies on method_missing
    # which in turn sometimes calls this method (creating infinite recursion)
    model_id = get('model_types')[name]
    return nil if model_id.nil?
    
    # perform a lookup; nil will be returned if the model doesn't exist
    model = @models.find(model_id)
    @cached_models[name] = model
    @cached_models[model.name] = model
    @cached_records[model.id] = model
  end
  
  # Retrieve a model by its full name ('Model' as opposed to 'models')
  def model(name)
    # get is required here instead calling 'model_types' explicitly as that relies
    # on method_missing which in turn sometimes calls this method (creating
    # infinite recursion)
    return nil if name.nil?
    model = @cached_models[name]
    return model unless model.nil?
    model_by_plural_name(get('model_plural_names')[name])
  end
end
