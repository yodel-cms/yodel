module Yodel
  class Model < MongoModel
    attr_reader :unscoped, :record_class
    collection 'models'
    
    field :name, String, required: true
    field :fields, Hash, required: true
    field :triggers, Array
    field :functions, Hash
    field :associations, Hash
    field :icon, String
    field :record_class, String
    
    has_many    :mixins, :model
    has_many    :descendants, :model
    has_many    :allowed_children, :model
    has_many    :allowed_parents, :model
    belongs_to  :parent, :model
    belongs_to  :view_group, :group
    belongs_to  :update_group, :group
    belongs_to  :delete_group, :group
    belongs_to  :create_group, :group
    
    def initialize(site, values={})
      @cached_records_by_name = {}      
      unless values.empty?
        @unscoped     = Yodel::Record.scoped_for(site)
        @scope        = Yodel::Record.scoped_for(site, '_model' => get_raw('descendants'))
        @record_class = Object.module_eval(document['klass'])
      end
      super
    end
    
    # create field sub classes for object id, array, etc. etc.
    # association class
    # remove references to site in query
    
    
    # ----------------------------------------
    # Records
    # ----------------------------------------
    extend Forwardable
    def_delegators :@scope, :where, :fields, :limit, :skip, :sort,
                            :count, :last, :first, :all, :paginate,
                            :find, :find!, :exists?, :exist?, :find_each
    
    # Load a record from a mongo document. If this model is not the model
    # of the record, the appropriate model is found and used instead.
    def load(values)
      return nil if values.nil?
      if values['_model'] != id
        site.models.find(values['_model']).load(values)
      else
        super
      end
    end
    
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
    
    # Simple lookup operator for models that have records with unique names.
    # Used as if the model object was a hash: site.emails['name']
    def [](name)
      unless @cached_records_by_name.key?(name)
        record = self.where(name: name).first
        @cached_records_by_name[name] = record
        site.cached_records[record.id] = record unless record.nil?
      end
      @cached_records_by_name[name]
    end
    
    
    # ----------------------------------------
    # Callbacks
    # ----------------------------------------
    # extend callbacks to work with mixins
    CALLBACKS.each do |callback|
      eval "
        def run_before_#{callback}_callbacks
          before_completed = self.class._before_#{callback}_callbacks.dup
          super
          
          mixins.collect {|mixin| mixin.class._before_#{callback}_callbacks}.flatten.each do |callback|
            unless before_completed.include?(callback)
              send callback
              before_completed << callback
            end
          end
        end
      
        def run_after_#{callback}_callbacks
          after_completed = self.class._after_#{callback}_callbacks.dup
          super
          
          mixins.collect {|mixin| mixin.class._after_#{callback}_callbacks}.flatten.each do |callback|
            unless after_completed.include?(callback)
              send callback
              after_completed << callback
            end
          end
        end
      "
    end
    
    
    # ----------------------------------------
    # Hierarchy
    # ----------------------------------------
    def ancestors
      next_parent = parent
      Enumerator.new do |models|
        break if next_parent.nil?
        models.yield next_parent
        next_parent = next_parent.parent
      end
    end
    
    def children
      site.models.where(parent_id: id)
    end
    
    # Combine the full set of parents and mixins in a way that doesn't duplicate models
    # if mixins would cause a duplicate, and maintains the correct position of mixins in
    # the inheritance tree for this model, any parents, and any mixins (and their mixins)
    def parents_and_mixins
      models = parent.try(:parents_and_mixins) || []
      mixins.each do |mixin_name|
        models |= site.model(mixin_name).parents_and_mixins
      end
      models << self
    end
    
    def all_record_fields(include_parents_and_mixins=true)
      if include_parents_and_mixins
        parents_and_mixins.each_with_object({}) do |ancestor, fields|
          fields.merge! ancestor.record_fields(false)
        end
      else
        model_fields.each_with_object({}) do |field, fields|
          fields[field['name']] = field
        end
      end
    end
  
  
    # ----------------------------------------
    # Admin interface
    # ----------------------------------------
    def allowed_children_and_descendants
      allowed_children.collect(&:descendants).flatten.uniq
    end
    
    def allowed_child?(other_model)
      allowed_children_and_descendants.include?(other_model)
    end

    # Based on the list of allowed parents, returns true if the supplied
    # model is a descendant of a valid parent of this model.
    def allowed_parent?(other_model)
      other_model_ancestors = other_model.ancestors.to_a
      allowed_parents.any? {|parent| other_model_ancestors.include?(parent)}
    end

    # Returns an array of all allowed children and descendants of those
    # children. This list respects both allowed_children and allowed_parents
    # restrictions, so Yodel::Page (which allows children that are
    # descendants of Page) won't include Yodel::Article which can only
    # exist under a Yodel::Blog page, even though Yodel::Article is a
    # descendant of Yodel::Page.
    def valid_children
      allowed_children_and_descendants.select {|child| child.valid_parent?(self)}
    end
    
    def valid_child?(other_model)
      valid_children.include?(other_model)
    end
    
    
    # ----------------------------------------
    # Permissions
    # ----------------------------------------
    def user_allowed_to?(user, action, record)
      case action
      when :view
        group = view_group
      when :update
        group = update_group
      when :delete
        group = delete_group
      when :create
        group = create_group
      end
    
      return true if group.nil?
      group.permitted?(user, record)
    end
  
    def user_allowed_to_view?(user, record)
      user_allowed_to?(user, :view, record)
    end
  
    def user_allowed_to_update?(user, record)
      user_allowed_to?(user, :update, record)
    end
  
    def user_allowed_to_delete?(user, record)
      user_allowed_to?(user, :delete, record)
    end
  
    def user_allowed_to_create?(user, record)
      user_allowed_to?(user, :create, record)
    end
    
    
    # ----------------------------------------
    # Migrations
    # ----------------------------------------
    # Convenience method for migrations, so modifications can be specified with
    # site.model_name.modify { field ... etc. }
    def modify(&block)
      instance_eval block
      save
    end
    
    def add_field(name, type, options={})
      name = name.to_s
      
      # preconditions
      raise Yodel::InvalidModelField.new("Duplicate field name") if record_fields.key?(name)
      raise Yodel::InvalidModelField.new("Type must be a known yodel field type") unless valid_type?(type)
      raise Yodel::InvalidModelField.new("Field name cannot start with an underscore") if name.start_with?('_')
      
      # add the field to the model and subclasses
      record_fields[name] = Yodel::Field.new(name, type, options)
    end
    
    def remove_field(name)
      field = record_fields.delete(name.to_s)
      raise Yodel::InvalidModelField.new("Unknown field name") if field.nil?
    end
    
    # Create a new model which inherits from the current model. If supplied, a block
    # is run and passed a reference to the new model.
    def create_model(name, options={})
      raise "create_model must be called on the root model instance only" unless self.name == 'Model'
      raise "Model name '#{name}' is not unique" if site.model_plural_names.key?(name)
      
      # create a new instance of model
      child = new
      child.name = name
      if options[:inherits]
        parent_model = site.model(options[:inherits])
        child.parent_id = parent_model.id
        child.klass = parent_model.get_field('klass')
      end
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
    
    # Add a new mixin to this model
    def add_mixin(model)
      raise Yodel::InvalidMixin.new("#{model_name} already mixed in to this model") if mixins.include?(model)
      raise Yodel::InvalidMixin.new("Mixin cannot be a parent") if ancestors.include?(model)
      
      # for all intents and purposes, by mixing in a model, we are a subtype of that model
      model.add_descendant(self)
      mixins << model
      save
    end
    
    # Remove a mixin from this model
    def remove_mixin(model)
      model.remove_descendant(self)
      mixins.delete(model)
      save
    end
    
    # Destroys all records which are instances of this model, removes a reference to
    # the model from the parent site, and repeats for any child models of the model.
    def destroy
      # remove this model from the model tree
      parent.try(:remove_descendant, self)
      mixins.each {|mixin| mixin.remove_descendant(self)}
      
      # destroy any child models, and all record instances
      children.each(&:destroy)
      all.each(&:destroy)
      
      # remove the association between the site and this model
      site.model_types.delete(name.underscore.pluralize)
      site.model_plural_names.delete(name)
      site.save
      
      # destroy the model record
      super
    end
    
    
    protected
      def valid_type?(type)
        raise "Unimplemented"
      end
      
      def add_descendant(model)
        parent.try(:add_descendant, model)
        descendants << model unless descendants.include?(model)
        save
      end
      
      def remove_descendant(model)
        parent.try(:remove_descendant, model)
        descendants.delete(model)
        save
      end
  end
end
