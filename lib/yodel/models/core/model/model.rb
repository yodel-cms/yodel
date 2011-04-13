module Yodel
  class Model < Yodel::SiteRecord
    attr_reader :unscoped, :record_class
    collection  :models
    
    # ----------------------------------------
    # Fields
    # ----------------------------------------
    field :name, :string, required: true
    field :record_fields, :fields, required: true
    field :triggers, :array
    field :functions, :hash
    field :icon, :string
    field :record_class_name, :string, default: 'Record'
    field :searchable, :boolean, default: true
    field :indexes, :array, of: :strings
    
    
    # ----------------------------------------
    # Associations
    # ----------------------------------------
    many  :mixins, model: :model
    many  :descendants, model: :model
    many  :allowed_children, model: :model
    many  :allowed_parents, model: :model
    one   :parent, model: :model
    one   :view_group, model: :group
    one   :update_group, model: :group
    one   :delete_group, model: :group
    one   :create_group, model: :group
    one   :default_child_model, model: :model
    many  :children, model: :model, store: false, foreign_key: 'parent'
    
    
    def initialize(site, values={})
      @cached_records_by_name = {}
      super
      @unscoped     = Yodel::Record.scoped_with_constructor(site, self)
      @scope        = Yodel::Record.scoped_with_constructor(site, self, 'model' => get_raw('descendants'))
      @record_class = Object.module_eval(get_raw('record_class_name'))
    end
    
    def to_str
      "#<Model: #{name}>"
    end

    
    # ----------------------------------------
    # Records
    # ----------------------------------------
    extend Forwardable
    def_delegators :@scope, :where, :limit, :skip, :sort, :count,
                            :last, :first, :all, :paginate, :find,
                            :find!, :exists?, :exist?, :find_each
    
    # Load a record from a mongo document. If this model is not the model
    # of the record, the appropriate model is found and used instead.
    def load(site, values)
      return nil if values.nil?
      if values['model'] != id
        site.models.find(values['model']).load(site, values)
      else
        record_class.new(self, site, values)
      end
    end
    
    def new(values={})
      record_class.new(self, site).tap {|record| record.update(values, false)}
    end
    
    # Scope to retrieve all root records of a model type under a site, e.g
    # Yodel::Groups.roots(site). Returns all records with a nil parent.
    def roots
      self.where(parent: nil).order('index asc')
    end
    
    # Scope to retrieve the first (or only) root record of a model under a
    # site, e.g Yodel::Page.root(site) will retrieve the root page of a site
    def root
      self.where(parent: nil).order('index asc').first
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
    
    def all_record_fields
      parents_and_mixins.each_with_object({}) do |ancestor, fields|
        fields.merge! ancestor.record_fields # FIXME: should this be record_fields or all_record_fields?
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
      instance_eval &block
      save
    end
    
    # TODO: modify_field
    
    def add_field(name, type, options={})
      name = name.to_s
      
      # preconditions
      raise Yodel::InvalidModelField.new("Duplicate field name") if record_fields.key?(name)
      raise Yodel::InvalidModelField.new("Type must be a known yodel field type") unless valid_type?(type)
      raise Yodel::InvalidModelField.new("Field name cannot start with an underscore") if name.start_with?('_')
      
      # add the field to the model and subclasses
      field_type = Yodel::Field.field_from_type(type.to_s)
      field = field_type.new(name, options.merge(type: type.to_s))
      Yodel::RecordIndex.add_index_for_field(self, field) if field.index?
      record_fields[name] = field
    end
    
    def remove_field(name)
      field = record_fields.delete(name.to_s)
      raise Yodel::InvalidModelField.new("Unknown field name") if field.nil?
      RecordIndex.remove_index_for_field(self, field) if field.index?
    end
    
    # TODO: modify versions of the association methods
    
    def add_embed_many(name, options={}, &block)
      embedded_field = add_field(name, 'many_embedded', options)
      embedded_field.instance_exec(embedded_field, &block) if block_given?
    end
    
    def remove_embed_many(name)
      remove_field(name)
    end
    
    def add_embed_one(name, options={}, &block)
      embedded_field = add_field(name, 'one_embedded', options)
      embedded_field.instance_exec(embedded_field, &block) if block_given?
    end
    
    def remove_embed_one(name)
      remove_field(name)
    end
    
    def add_many(name, options={})
      type = (options[:store] == false) ? 'many_query' : 'many_store'
      add_field(name, type, options)
    end
    
    def remove_many(name)
      remove_field(name)
    end
    
    def add_one(name, options={})
      type = (options[:store] == false) ? 'one_query' : 'one_store'
      add_field(name, type, options)
    end
    
    def remove_one(name)
      remove_field(name)
    end
    
    def add_index(name, *fields)
      raise Yodel::InvalidIndex, 'Indexes must be built on at least one field' if fields.empty?
      spec = fields.collect do |field|
        if field.is_a?(Array)
          [field.first.to_s, (field.last == :desc) ? Mongo::DESCENDING : Mongo::ASCENDING]
        else
          [field.to_s, Mongo::ASCENDING]
        end
      end
      RecordIndex.add_index_for_model(self, name, spec)
      indexes << name
    end
    
    def remove_index(name)
      RecordIndex.remove_index_for_model(self, name)
      indexes.delete(name)
    end
    
    # Create a new model which inherits from the current model. If supplied, a block
    # is run and passed a reference to the new model.
    def create_model(name, &block)
      name = name.to_s.tableize
      raise "Model name '#{name}' is not unique" if site.model_types.key?(name)
      
      # create a new instance of model
      child = self.class.new(site)
      child.name = name.camelcase
      child.parent = self
      child.record_class_name = record_class_name
      child.save
      
      # insert the model in to the site models list
      class_name = name.classify
      site.model_types[name] = child.id
      site.model_plural_names[class_name] = name
      site.save
      
      # append the model to ancestor descendant lists (these are used in queries to
      # restrict the type of records returned, e.g pages.all => _model: ['Page', ...]
      child.add_descendant(child)
      child.instance_exec(child, &block) if block_given?
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
      
      # destroy model subclasses, and all record instances
      children.each(&:destroy)
      all.each(&:destroy)
      
      # remove the association between the site and this model
      site.model_types.delete(name.underscore.pluralize)
      site.model_plural_names.delete(name)
      site.save
      
      # remove any remaining indexes
      indexes.each do |name|
        RecordIndex.remove_index_for_model(self, name)
      end
      
      record_fields.each do |name, field|
        RecordIndex.remove_index_for_field(self, field) if field.index?
      end
      
      # destroy the model record
      super
    end
    
    
    protected
      def valid_type?(type)
        Yodel::Field.field_from_type(type.to_s).present?
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
