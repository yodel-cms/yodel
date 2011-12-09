class Site < MongoRecord
  attr_reader :cached_records, :cached_models
  
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
  
  def self.load_from_site_yaml(path)
    Site.new(YAML.load_file(path)).tap do |site|
      site.root_directory = File.dirname(path)
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
