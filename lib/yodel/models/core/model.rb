#     # Specify the types allowed to exist as children under this model. For
#     # instance Articles may only exist under Blog: allowed_children Article
#     def self.allowed_children(*args)
#       @allowed_children = (args.first.nil? ? [] : args)
#     end
#     
#     # Returns a list of all allowed children and their descendants.
#     def self.allowed_children_and_descendants
#       (@allowed_children || []).collect {|type| type.descendants + [type]}.flatten.uniq.select(&:visible?)
#     end
#     
#     # Specify the parent types this model is allowed to exist under. For
#     # instance Articles may only exist under Blog: allowed_parents Blog
#     def self.allowed_parents(*args)
#       @allowed_parents = (args.first.nil? ? [] : args)
#     end
#     
#     # Based on the list of allowed parents, returns true if the supplied
#     # class is a descendant of a valid parent of this model.
#     def self.valid_parent?(klass)
#       return true if @allowed_parents.nil?
#       ancestors = klass.ancestors.collect(&:name)
#       @allowed_parents.each {|parent| return true if ancestors.include?(parent.name)}
#       false
#     end
# 
#     # Returns an array of all allowed children, and descendants of those
#     # children. This list respects both allowed_children and allowd_parents
#     # restrictions, so Yodel::Page (which allows children which are
#     # descendants of Page) won't include Yodel::Article which can only
#     # exist under a Yodel::Blog page, even though Yodel::Article is a
#     # descendant of Yodel::Page.
#     def self.valid_children
#       @valid_children ||= allowed_children_and_descendants.select {|child| child.valid_parent?(self)}
#     end
#     
#     # Copy class instance attributes down the inheritance chain
#     def self.inherited(child)
#       super(child)
#       child.instance_variable_set('@allowed_children', @allowed_children)
#     end
#     
# 
#     
#     # FIXME: this needs to be extracted out to the different key types?
#     # def self.cleanse_hash(hash)
#     #   # for readability rename '_id' to 'id',
#     #   # and '_type' to 'type'
#     #   if hash.has_key?('_id')
#     #     id = hash.delete('_id')
#     #     hash['id'] = id.to_s
#     #   end
#     #   if hash.has_key?('_type')
#     #     type = hash.delete('_type')
#     #     hash['type'] = type
#     #   end
#     #   
#     #   # we don't need to store which site the record belongs to
#     #   hash.delete('site_id')
#     #   
#     #   # or the search keywords that are generated
#     #   hash.delete('yodel_search_keywords') if hash.has_key?('yodel_search_keywords')
#     #   
#     #   # attributes starting with an underscore are private
#     #   hash.delete_if {|key, value| key.start_with? '_'}
#     #   
#     #   # change all references (values of type ObjectID)
#     #   # to a string of the object ID, cleanse embedded
#     #   # documents, remove "_id" from all keys, and change
#     #   # date and time values in to a format suitable for
#     #   # clients to read appropriately
#     #   hash.each do |key, value|
#     #     hash[key] = value.to_s if value.is_a?(BSON::ObjectId)
#     #     hash[key] = cleanse_hash(value) if value.is_a?(Hash)
#     #     hash[key] = value.force_encoding("UTF-8") if value.is_a?(String)
#     #     
#     #     if self.keys[key.to_sym].try(:type) && self.keys[key.to_sym].type.ancestors.include?(Tags)
#     #       hash[key] = Tags.new(value).to_s
#     #       next
#     #     end
#     #     
#     #     if key.end_with?('_id')
#     #       hash.delete(key)
#     #       value_key = key.gsub('_id', '')
#     #       hash[value_key] = value unless hash.has_key?(value_key)
#     #       next
#     #     end
#     #     
#     #     # hack to get around mongo mapper mapping all dates to time objects...
#     #     if value.is_a?(Time) || value.is_a?(Date)
#     #       if self.keys.has_key?(key) && !self.keys[key].type.nil?
#     #         type = self.keys[key].type
#     #       else
#     #         type = value.class
#     #       end
#     #     
#     #       if type.ancestors.include?(Date)
#     #         hash[key] = value.strftime("%d %b %Y")
#     #       elsif type.ancestors.include?(Time)
#     #         # FIXME: this is just horrible.... only done to make the admin interface easy
#     #         hash.delete(key)
#     #         hash[key + '_date'] = value.strftime("%d %b %Y")
#     #         hash[key + '_hour'] = value.localtime.hour
#     #         hash[key + '_min']  = value.localtime.min
#     #       end
#     #       next
#     #     end
#     #     
#     #     # has_many associations stored in an array need
#     #     # to have ObjectID's converted to strings
#     #     if value.is_a?(Array)
#     #       hash[key] = value.collect do |val|
#     #         val.is_a?(BSON::ObjectId) ? val.to_s : val
#     #       end
#     #     end
#     #   end
#     #   
#     #   hash
#     # end
#     # 
#     # def to_json_hash
#     #   self.class.cleanse_hash(attributes)
#     # end

module Yodel
  class Model < Record
    def initialize(model, document=nil, site=nil)
      unless document.nil?
        @scope = Yodel::Query.new(self, document['_site_id'], document['descendants'])
        @klass = Object.module_eval(document['klass'])
      end
      
      if model.nil?
        super(self, document, site)
      else
        super
      end
    end
    
    def klass
      @klass
    end
    
    def new(values={})
      @klass.new(self, nil, site).tap {|record| record.update(values)}
    end
  
    def load(values)
      return nil if values.nil?
      model = site.model(values['_model'])
      model.klass.new(model, values)
    end
    
    def default_values
      model_fields.each_with_object(parent.try(:default_values) || {}) do |field, values|
        default_value = field['default']
        default_value = eval(default_value) if field['eval']
        values[field['name']] = default_value
      end
    end
    
    def all_model_fields
      model_fields.each_with_object(parent.try(:all_model_fields) || {}) do |field, fields|
        fields[field['name']] = field
      end
    end
    
    def model_fields
      @changed['model_fields'] || @document['model_fields']
    end
    
    def reload
      @all_fields = nil
      super
    end
    
    
    # ----------------------------------------
    # Migrations
    # ----------------------------------------
    # Convenience method for migrations, so modifications can be specified with
    # site.model_name.modify { add_field ... etc. }
    def modify
      yield self
      save
    end
    
    def self.add_field(name, type, collection, options={})
      name = name.to_s
      
      # ensure type is a valid module
      unless valid_type?(type)
        raise Yodel::InvalidModelField.new("Type must implement expected to/from mongo/json API")
      end
      
      # a field can't be added twice to the same model
      raise Yodel::InvalidModelField.new("Duplicate field name") if field?(collection, name)
      
      # field names starting with an underscore are reserved
      raise Yodel::InvalidModelField.new("Field name cannot start with an underscore") if name.start_with?('_')
      
      # add the field to the model and subclasses
      collection << options.stringify_keys.merge('name' => name.to_s, 'type' => type.name.to_s)
      # TODO: check for index options on fields
    end
    
    # Add a single field with a name and type. Children inherit parent fields, but
    # can override a field's definition by explicitly calling this method themselves.
    def add_field(name, type, options={})
      self.class.add_field(name, type, model_fields, options)
    end
    
    def self.remove_field(name, collection)
      name = name.to_s
      collection.each do |field|
        if field['name'] == name
          collection.delete(field)
          return
        end
      end
      raise Yodel::InvalidModelField.new("Unknown field name")
    end
    
    # Remove a single field from the current model. Any children will also have
    # this field removed unless they explicitly define it themselves.
    def remove_field(name)
      self.class.remove_field(name, model_fields)
    end
    
    # Create a new model which inherits from the current model. If supplied, a block
    # is run and passed a reference to the new model.
    def create_model(name, parent=nil)
      raise "create_model must be called on the root model instance only" unless self.name == 'Model'
      raise "Model name '#{name}' is not unique" if site.model_plural_names.key?(name)
      
      # create a new instance of model
      child = new
      child.name = name
      child.parent_id = parent.id if parent
      child.save
      
      # insert the model in to the site models list
      plural_name = name.underscore.pluralize
      site.model_types[plural_name] = child.id
      site.model_plural_names[name] = plural_name
      site.save
      
      # append the model to ancestor descendant lists (these are used in queries to
      # restrict the type of records returned, e.g pages.all => _model: ['Page', ...]
      child.add_descendant(name)
      yield child if block_given?
      child.save
    end
    
    # Destroys all records which are instances of this model, removes a reference to
    # the model from the parent site, and repeats for any child models of the model.
    def destroy
      # remove this model from the model tree
      parent.try(:remove_descendant, name)
      
      # destroy any child models
      children.each(&:destroy)
      
      # destroy all record instances of this model
      all.each(&:destroy)
      
      # remove the association between the site and this model
      site.model_types.delete(name.underscore.pluralize)
      site.save
      
      # destroy the model record
      super
    end
    
    
    # ----------------------------------------
    # Querying
    # ----------------------------------------
    extend Forwardable
    def_delegators :@scope, :where, :fields, :limit, :skip, :sort,
                            :count, :last, :first, :all, :paginate,
                            :find, :find!, :exists?, :exist?, :find_each
                            
    # Scope to retrieve all root records of a model type under a site, e.g
    # Yodel::Groups.roots(site). Returns all records with a nil parent.
    def roots
      self.where(_parent_id: nil).order('index asc')
    end
    
    # Scope to retrieve the first (or only) root record of a model under a
    # site, e.g Yodel::Page.root(site) will retrieve the root page of a site
    def root
      self.where(_parent_id: nil).order('index asc').first
    end
    
    # Retrieve a model specified in conditions. Conditions is a mongo driver
    # query hash, such as {_id: id} or {name: name}
    def self.find_by(site, conditions)
      document = COLLECTION.find_one(conditions.merge(_site_id: site.id))
      return nil if document.nil?
      
      # a bit of a dirty hack... the root Model record is both a model and
      # a record, so it can't reference itself when being initialised (since
      # it doesn't exist yet). For other models we can pass a reference.
      model = document['name'] != 'Model' ? site.models : nil
      Model.new(model, document, site)
    end
    
    
    protected
      def self.field?(collection, name)
        collection.any? {|field| field['name'] == name}
      end
      
      def self.valid_type?(type)
        type.respond_to?(:to_mongo) && type.respond_to?(:from_mongo) &&
        type.respond_to?(:to_json) && type.respond_to?(:from_json)
      end
      
      def add_descendant(name)
        parent.try(:add_descendant, name)
        descendants << name
        save
      end
      
      def remove_descendant(name)
        parent.try(:add_descendant, name)
        descendants.delete(name)
        save
      end
  end
end
