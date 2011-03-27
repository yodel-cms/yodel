module Yodel
  class Record
    COLLECTION    = Yodel.config.db_connection.collection('records', pk: Yodel::PrimaryKeyFactory)
    attr_reader   :model, :site, :mixins, :document, :typecast, :changed
    attr_accessor :core_model
    
    def initialize(model, document=nil, site=nil)
      @model    = model
      @new      = document.nil?
      @site     = site || model.try(:site)
      @mixins   = create_mixin_instances(document)
      
      # load and typecast either an instance of the model, the set of default values for the model
      @document = document || default_document
      @typecast = {} # typecast versions of original document values
      @changed  = {} # typecast versions of changed values
      typecast_values # cache typecast versions of original values
      
      # reassign the main object's instance variables, and delegate database access methods, to any mixins
      delegate_mixins
    end
  
    def default_document
      { '_id' => Yodel::PrimaryKeyFactory.pk,
        '_model' => @model.name,
        '_site_id' => @model.raw_values['_site_id'],
        '_parent_id' => nil,
        '_index' => nil,
        '_eigenmodel' => []
      }.merge(@model.default_values)
    end
    
    def create_mixin_instances(document)
      return [] if model.nil? || self.is_a?(Model)
      model.mixins.collect do |model_name|
        mixin_model = site.model(model_name)
        mixin_model.klass.new(mixin_model, document, site)
      end.compact
    end
    
    def delegate_mixins
      extend SingleForwardable
      ancestors = self.class.ancestors
      included_classes = []
      
      @mixins.each_with_index do |mixin, index|
        # reassign the mixin object's instance vars
        %w{@model @new @site @document @typecast @changed}.each do |var|
          mixin.instance_variable_set(var, instance_variable_get(var))
        end
        
        # delegate database access to the main object
        mixin.extend SingleForwardable
        mixin.core_model = self
        mixin.def_delegators :@core_model, :save, :save_without_validation, :destroy,
                                           :update, :reload, :all_fields, :to_json,
                                           :from_json, :to_form, :from_form
        
        # delegate mixin instance methods (if custom classes are used) to the mixin
        # so mixing in user to a page makes the page appear to have user methods
        # such as :reset_password. Delegation of methods continues up the class
        # hierarchy until the class ancestry of the main object and mixin converge
        # (only unique classes are mixed in). So mixing a user subclass into a page
        # would mixin the subclass, followed by user. We stop at record since
        # both page and the user subclass inherit from it.
        mixin.class.ancestors.each do |klass|
          break if ancestors.include?(klass)
          next if included_classes.include?(klass)
          def_delegators "@mixins[#{index}]", *klass.instance_methods(false)
          included_classes << klass
        end
      end
    end
    
    
    # ----------------------------------------
    # Database
    # ----------------------------------------
    def save
      valid? ? save_without_validation : false
    end
  
    def save_without_validation
      raise Yodel::DestroyedRecord if @destroyed
      
      _run_save_callbacks do
        if new?
          _run_create_callbacks { perform_save }
        else
          _run_update_callbacks { perform_save }
        end
      end
      
      @new = false
      true
    end
    
    def destroy
      return if @new || @destroyed
      _run_destroy_callbacks do
        COLLECTION.remove(_id: @document['_id'])
      end
      @destroyed = true
    end
    
    def update(values, options={save: true})
      values.each {|field, value| set_field(field.to_s, value)}
      save if options[:save]
    end
    
    def reload
      # FIXME: need to remove all instance vars prior to calling initialize
      return if @new || @destroyed
      initialize(@model, COLLECTION.find_one(_id: id), @site)
    end
    
    
    # ----------------------------------------
    # Equality
    # ----------------------------------------
    def eql?(other)
      other.is_a?(Record) && other.model_name == self.model_name && other.id == self.id
    end
    
    alias :== :eql?

    def hash
      id.hash
    end
    
    
    # ----------------------------------------
    # Fields
    # ----------------------------------------
    # TODO: field modelling can be abstracted out to a module and included in Model and Record and the Embedded field type
    def all_fields
      eigenmodel_fields = eigenmodel.each_with_object({}) {|field, hash| hash[field['name']] = field}
      model.all_model_fields.merge(eigenmodel_fields)
    end
    
    def add_field(name, type, options={})
      name = name.to_s
      Yodel::Model.add_field(name, type, eigenmodel, options)
      @document[name] = options['default'] || options[:default]
      @typecast[name] = type.from_mongo(self, name, @document[name])
    end
    
    def remove_field(name)
      Yodel::Model.remove_field(name, eigenmodel)
      @document.delete(name)
      @typecast.delete(name)
      @changed.delete(name)
    end
    
    
    # ----------------------------------------
    # Accessors
    # ----------------------------------------
    def inspect;        {changed: @changed, typecast: @typecast, original: @document}.inspect; end
    def model_name;     @document['_model']; end
    def parent_id=(i);  @document['_parent_id'] = i; end
    def parent_id;      @document['_parent_id']; end
    def eigenmodel;     @document['_eigenmodel']; end
    def site_id;        @document['_site_id']; end
    def index=(i);      @document['_index'] = i; end
    def index;          @document['_index']; end
    def id;             @document['_id']; end
    def raw_values;     @document; end
    def new?;           @new; end
    
    # parent acts as an association
    def parent
      return nil if model.nil?
      @parent ||= model.first(_id: @document['_parent_id'])
    end
    
    def parent=(parent_record)
      @document['_parent_id'] = parent_record.nil? ? nil : parent_record.id
      @parent = parent_record
    end
    
    # values are stored in the documents hash
    def method_missing(name, *args, &block)
      # TODO: prevent access to certain fields here; prevent assignment to special fields
      # strip off any trailing modifier characters to get a raw field name
      field = name.to_s
      
      if field.end_with?('_changed?')
        action = :changed
        field['_changed?'] = ''
      elsif field.end_with?('=')
        action = :setter
        field = field[0...-1]
      elsif field.end_with?('?')
        action = :blank
        field = field[0...-1]
      elsif field.end_with?('_was')
        action = :was
        field['_was'] = ''
      else
        action = :getter
      end
    
      return super unless @document.key?(field)
      
      case action
        when :getter
          get_field(field)
        when :setter
          set_field(field, args.first)
        when :blank
          !get_field(field).blank?
        when :changed
          field_changed?(field)
        when :was
          field_was(field)
      end
    end
    
    def set_field(field, value)
      @changed[field] = value
    end
    
    def get_field(field)
      @changed[field] || @typecast[field] || generate_uncached_field(field)
    end
    
    def generate_uncached_field(field)
      Object.module_eval(all_fields[field]['type']).from_mongo(self, field, @document[field])
    end
    
    def field_changed?(field)
      @changed.key?(field)
    end
    
    def field_was(field)
      @typecast[field]
    end
    
    def typecast_values
      all_fields.each do |name, options|
        type = Object.module_eval(options['type'])
        unless type.uncacheable?
          value = type.from_mongo(self, name, @document[name])
          @typecast[name] = value
          @changed[name] = value if type.mutable?
        end
      end
    end
    
    def copy_mutable_values
      all_fields.each_with_object({}) do |pair, changed|
        name, options = pair
        type = Object.module_eval(options['type'])
        if type.mutable? && !type.uncacheable?
          changed[name] = @typecast[name]
        end
      end
    end
    
    
    # ----------------------------------------
    # Conversions
    # ----------------------------------------
    def to_json
      {
        id: id.to_s,
        parent_id: parent_id.nil? ? nil : parent_id.to_s,
        model: model_name,
        index: index,
        fields: all_fields.collect do |name, options|
          type_name = options['type']
          type = Object.module_eval(type_name)
          unless type.uncacheable? || options['display'] == false
            value = type.to_json(self, name, @document[name])
            {name: name, type: type_name, value: value}
          else
            nil
          end
        end.compact
      }
    end
    
    def from_json(json)
      # FIXME: need to handle _index, _parent_id etc.
      return unless json['fields']
      json['fields'].each do |field|
        name = field['name']
        options = all_fields[name]
        next if options.nil?
        @changed[name] = Object.module_eval(options['type']).from_html_field(self, name, field['value'])
      end
    end
    
    def to_form(url, options={})
      method = options.delete(:method) || 'post'
      if options[:only]
        fields = options[:only].collect {|name| all_fields[name.to_s]}
      else
        fields = all_fields.values
      end
      
      html = "<form action='#{url}' method='#{method}'>"
      fields.each do |options|
        type = Object.module_eval(options['type'])
        name = options['name']
        
        unless type.uncacheable? || options['display'] == false
          input = type.to_html_field(self, name, @document[name]).to_s
          if input
            html += "<p><label for='#{name}'>#{name.humanize}</label>#{input}</p>"
          end
        end
      end
      
      # extra parameters passed in as hidden fields
      options[:params] ||= {}
      options[:params].each {|name, value| html += "<input type='hidden' name='#{name}' value='#{value}'>"}
      html + "<p><input type='submit'></p></form>"
    end
    
    def from_form(values)
      values.each do |name, value|
        options = all_fields[name]
        next if options.nil?
        @changed[name] = Object.module_eval(options['type']).from_html_field(self, name, value)
      end
    end
    
    
    # ----------------------------------------
    # Callbacks & Validations
    # ----------------------------------------
    CALLBACKS = %w{save create update destroy validation}
    CALLBACKS.each do |callback|
      eval "
        @_before_#{callback}_callbacks = []
        @_after_#{callback}_callbacks = []
        
        def self._before_#{callback}_callbacks
          @_before_#{callback}_callbacks
        end
        
        def self._after_#{callback}_callbacks
          @_after_#{callback}_callbacks
        end
        
        def self.before_#{callback}(*callbacks)
          @_before_#{callback}_callbacks += callbacks
        end
        
        def self.after_#{callback}(*callbacks)
          @_after_#{callback}_callbacks += callbacks
        end
        
        def _run_before_#{callback}_callbacks
          self.class._before_#{callback}_callbacks.each {|method| send method}
        end
        
        def _run_after_#{callback}_callbacks
          self.class._after_#{callback}_callbacks.each {|method| send method}
        end
        
        def _run_#{callback}_callbacks(&block)
          _run_before_#{callback}_callbacks
          mixins.each(&:_run_before_#{callback}_callbacks) unless self.is_a?(Model)
          yield if block_given?
          mixins.each(&:_run_after_#{callback}_callbacks) unless self.is_a?(Model)
          _run_before_#{callback}_callbacks
        end
      "
    end
    
    def self.inherited(child)
      super(child)
      CALLBACKS.each do |callback|
        before_callbacks = instance_variable_get("@_before_#{callback}_callbacks")
        after_callbacks = instance_variable_get("@_after_#{callback}_callbacks")
        child.instance_variable_set("@_before_#{callback}_callbacks", before_callbacks)
        child.instance_variable_set("@_after_#{callback}_callbacks", after_callbacks)
      end
    end
    
    def valid?
      _run_validation_callbacks do
      end
    end

    
    # ----------------------------------------
    # Hierarchical methods
    # ----------------------------------------
    # insertion and deletion to maintin the integrity of the 'index' field
    before_validation :append_to_siblings
    before_destroy    :remove_from_siblings
    
    def append_to_siblings
      return unless new?
      highest_index = siblings.last.try(:index) || 0
      self.index = highest_index + 1
    end

    # FIXME: these need to be atomic ops
    def insert_in_siblings(new_index)
      remove_from_siblings if index
      siblings.where(:_index.gte => new_index).each do |sibling|
        sibling.index += 1
        sibling.save
      end
      self.index = new_index
    end

    def remove_from_siblings
      siblings.where(:_index.gte => index).each do |sibling|
        sibling.index -= 1
        sibling.save
      end
      self.index = nil
      self.parent = nil
    end
    
    # Children of this record (other records which have this record as a parent)
    def children
      model.where(_parent_id: id).order('index asc')
    end
        
    # Siblings of this record (other records with the same parent)
    def siblings
      model.where(:_parent_id => parent_id, :_id.ne => id).order('index asc')
    end
    
    # All descendent children of this record, i.e children, grandchildren and so on.
    def all_children
      [self, children.collect(&:all_children)].flatten
    end

    # An array of parent records all the way back to a root record. e.g calling on
    # a page two levels deep would return: [page, parent, root]
    def parents
      [self, self.parent.try(:parents)].flatten.compact
    end
    
    # True if this record has no parent
    def root?
      parent_id.nil?
    end
    
    
    # ----------------------------------------
    # Search
    # ----------------------------------------
    before_save :update_search_keywords
    def update_search_keywords
      return unless !self.is_a?(Model) && model.searchable?
      search_terms = Set.new
      
      all_fields.each do |name, options|
        # TODO: we should cache somewhere which types do and do not contain the search_terms_set
        # method; this can also be used to automatically populate the searchable option on fields
        type = Object.module_eval(options['type'])
        next if options['searchable'] == false || !type.instance_methods.include?(:search_terms_set)
        
        value = get_field(name)
        next if value.nil?
        search_terms.merge(value.search_terms_set.collect(&:downcase))
      end
      
      self.search_keywords = search_terms.to_a
    end
    
    private
      def perform_save
        # merge the modified values back to the mongo document
        fields = all_fields
        @changed.each do |name, value|
          @document[name] = Object.module_eval(fields[name]['type']).to_mongo(self, name, value)
          @typecast[name] = value
        end
        
        # perform an update or insert of the raw values
        COLLECTION.save(@document)
        
        # after a save there are no changed fields
        @changed = copy_mutable_values
      end
  end
end
