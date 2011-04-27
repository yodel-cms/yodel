module Yodel
  class Model < Yodel::SiteRecord
    attr_reader :unscoped, :record_class
    collection  :models
        
    # ----------------------------------------
    # Fields
    # ----------------------------------------
    field :name, :string, validations: {required: {}}
    field :record_fields, :fields, validations: {required: {}}
    field :triggers, :array
    field :functions, :hash
    field :icon, :string, inherited: true
    field :record_class_name, :string, default: 'Record', inherited: true
    field :searchable, :boolean, default: true, inherited: true
    field :indexes, :array, of: :strings
    field :record_before_validation_callbacks, :array, of: :strings, inherited: true
    field :record_after_validation_callbacks, :array, of: :strings, inherited: true
    field :record_before_save_callbacks, :array, of: :strings, inherited: true
    field :record_after_save_callbacks, :array, of: :strings, inherited: true
    field :record_before_create_callbacks, :array, of: :strings, inherited: true
    field :record_after_create_callbacks, :array, of: :strings, inherited: true
    field :record_before_update_callbacks, :array, of: :strings, inherited: true
    field :record_after_update_callbacks, :array, of: :strings, inherited: true
    
    
    # ----------------------------------------
    # Associations
    # ----------------------------------------
    many  :mixins, model: :model
    many  :descendants, model: :model
    many  :allowed_children, model: :model, inherited: true
    many  :allowed_parents, model: :model, inherited: true
    one   :parent, model: :model
    one   :view_group, model: :group, inherited: true
    one   :update_group, model: :group, inherited: true
    one   :delete_group, model: :group, inherited: true
    one   :create_group, model: :group, inherited: true
    many  :children, model: :model, foreign_key: 'parent'
    one   :default_child_model, model: :model, inherited: true
    one   :new_child_page, model: :page, inherited: true
    
    
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
    # Callbacks
    # ----------------------------------------
    # TODO: use loops like in abstract record to write these functions
    def run_record_before_validation_callbacks(record)
      record_before_validation_callbacks.each {|fn| Yodel::Function.new(fn).execute(record)}
    end
    
    def run_record_after_validation_callbacks(record)
      record_after_validation_callbacks.each {|fn| Yodel::Function.new(fn).execute(record)}
    end
    
    def run_record_before_save_callbacks(record)
      record_before_save_callbacks.each {|fn| Yodel::Function.new(fn).execute(record)}
    end
    
    def run_record_after_save_callbacks(record)
      record_after_save_callbacks.each {|fn| Yodel::Function.new(fn).execute(record)}
    end
    
    def run_record_before_create_callbacks(record)
      record_before_create_callbacks.each {|fn| Yodel::Function.new(fn).execute(record)}
    end

    def run_record_after_create_callbacks(record)
      record_after_create_callbacks.each {|fn| Yodel::Function.new(fn).execute(record)}
    end
    
    def run_record_before_update_callbacks(record)
      record_before_update_callbacks.each {|fn| Yodel::Function.new(fn).execute(record)}
    end
    
    def run_record_after_update_callbacks(record)
      record_after_update_callbacks.each {|fn| Yodel::Function.new(fn).execute(record)}
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
    # Hierarchy
    # ----------------------------------------
    def ancestors
      next_parent = self
      Enumerator.new do |models|
        while next_parent
          models.yield next_parent
          next_parent = next_parent.parent
        end
      end
    end
    
    # Combine the full set of parents and mixins in a way that doesn't duplicate models
    # if mixins would cause a duplicate, and maintains the correct position of mixins in
    # the inheritance tree for this model, any parents, and any mixins (and their mixins)
    def parents_and_mixins
      models = parent.try(:parents_and_mixins) || []
      mixins.each do |mixin_model|
        models |= mixin_model.parents_and_mixins
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
    # TODO: ensure field name != a public method name
    
    def add_field(name, type, options={})
      name = name.to_s
      
      # preconditions
      raise Yodel::InvalidModelField.new("Duplicate field name") if record_fields.key?(name)
      raise Yodel::InvalidModelField.new("Type must be a known yodel field type") unless valid_type?(type)
      raise Yodel::InvalidModelField.new("Field name cannot start with an underscore") if name.start_with?('_')
      
      # add the field to the model and subclasses
      field_type = Yodel::Field.field_from_type(type.to_s)
      field = field_type.new(name, deep_stringify_keys(options.merge(type: type.to_s)))
      Yodel::RecordIndex.add_index_for_field(self, field) if field.index?
      record_fields[name] = field
    end
    
    def remove_field(name)
      field = record_fields.delete(name.to_s)
      raise Yodel::InvalidModelField.new("Unknown field name") if field.nil?
      RecordIndex.remove_index_for_field(self, field) if field.index?
    end
    
    # TODO: remove copy of this method when abstract_model is mixed in
    def deep_stringify_keys(hash)
      hash.each_with_object({}) do |(key, value), new_hash|
        new_hash[key.to_s] = (value.respond_to?(:to_hash) ? deep_stringify_keys(value) : value)
      end
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
      type = query_association?(options) ? 'many_query' : 'many_store'
      add_field(name, type, options)
    end
    
    def remove_many(name)
      remove_field(name)
    end
    
    def add_one(name, options={})
      type = query_association?(options) ? 'one_query' : 'one_store'
      add_field(name, type, options)
    end
    
    def remove_one(name)
      remove_field(name)
    end
    
    def query_association?(options)
      options[:store] == false || [:foreign_key, :extends, :through].any? {|opt| options[opt].present?}
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
      child.name = name.camelcase.singularize
      child.parent = self
      
      # inherited fields
      fields.each do |name, field|
        child.set(name, get(name)) if field.inherited?
      end
      
      # insert the model in to the site models list
      class_name = name.classify
      site.model_types[name] = child.id
      site.model_plural_names[class_name] = name
      site.save
      
      # append the model to ancestor descendant lists (these are used in queries to
      # restrict the type of records returned, e.g pages.all => _model: ['Page', ...]
      child.tap do |child|
        child.add_descendant(child)
        child.instance_exec(child, &block) if block_given?
        child.save
      end
    end
    
    # Add a new mixin to this model
    def add_mixin(model)
      raise Yodel::InvalidMixin.new("#{model.name} already mixed in to this model") if mixins.include?(model)
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
