class Site
  COLLECTION = Yodel.config.db_connection.collection('sites', pk: PrimaryKeyFactory)
  DEFAULT_DOCUMENT = {
    '_id' => PrimaryKeyFactory.pk,
    'model_plural_names' => {},
    'model_types' => {},
    'extensions' => [],
    'migrations' => [],
    'options' => {},
    'domains' => [],
    'name' => ''
  }
  
  def initialize(document=nil)
    @document = document || DEFAULT_DOCUMENT
    @cached_records = {}
    @cached_models = {}
    
    # static models
    @models = Model.scoped_for(self)
    @cached_models['Model'] = @cached_models['models'] = @models
    @cached_models['Trigger'] = @cached_models['triggers'] = Trigger.scoped_for(self)
    @cached_models['Task'] = @cached_models['tasks'] = Task.scoped_for(self)
  end
  
  
  # ----------------------------------------
  # Accessors
  # ----------------------------------------
  attr_reader :cached_records, :cached_models
  def id; @document['_id']; end
  
  # generate a getter/setter pair for each of the standard attributes
  DEFAULT_DOCUMENT.keys.each do |attribute|
    define_method(attribute) do
      @document[attribute]
    end
    
    define_method("#{attribute}=") do |value|
      @document[attribute] = value
    end
  end
  
  # TODO: a better interface is site.options.name.option; site.options.pages.permalink_character
  def option(path)
    component, option = path.split('.')
    options[component].try(:fetch, option, nil).try(:fetch, 'value', nil)
  end
  
  def log
    @log ||= Log.new(self)
  end
  
  def to_str
    "#<Site: #{id} (#{name})>"
  end
  
  alias :to_s :to_str
  
  
  # ----------------------------------------
  # Database
  # ----------------------------------------
  # Write a site back to the database. This method cannot be called after
  # destroying a site, and you must ensure the site has values for at
  # least the 'name' and 'domains' attributes.
  def save
    raise "Unable to save Site as it has been destroyed" if @destroyed
    raise "Site must have a name" if @document['name'].blank?
    raise "Site must have at least one domain" if @document['domains'].blank?
    COLLECTION.save(@document)
    true
  end

  # Destroy a site and all records associated with it
  def destroy
    return if @destroyed || @document['_id'].nil?
    Record::COLLECTION.remove(_site_id: @document['_id'])
    COLLECTION.remove(_id: @document['_id'])
    @destroyed = true
  end
  
  # When running migrations, it's easier to force a refresh of a site and its
  # model instances than to try and keep everything in sync manually
  def reload
    initialize(COLLECTION.find_one(_id: id))
  end
  
  # Query for a retrieve a single Site object based on a mongo criteria hash
  def self.find_by(conditions = {})
    site_data = COLLECTION.find_one(conditions)
    return nil if site_data.nil?
    Site.new(site_data)
  end
  
  # Retrieve an array of all site records
  def self.all
    COLLECTION.find.collect do |site_data|
      Site.new(site_data)
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
    # ensure the site has a reference to a model by this name
    model_id = @document['model_types'][name]
    return nil if model_id.nil?
    
    # perform a lookup; nil will be returned if the model doesn't exist
    model = @models.find(model_id)
    @cached_models[name] = model
    @cached_models[model.name] = model
    @cached_records[model.id] = model
  end
  
  # Retrieve a model by its full name ('Model' as opposed to 'models')
  def model(name)
    return nil if name.nil?
    model = @cached_models[name]
    return model unless model.nil?
    model_by_plural_name(@document['model_plural_names'][name])
  end
end