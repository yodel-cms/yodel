module Yodel
  class Record
    COLLECTION    = Yodel.config.db_connection.collection('records', pk: Yodel::PrimaryKeyFactory)
    attr_reader   :model, :site, :mixins, :document, :typecast, :changed
    attr_accessor :core_model # if this record is mixed in to another (core) record
    # FIXME: rename core_model to core_record
    
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
      return if @new || @destroyed
      
      # locally store the values we need to re-initialise the record
      _model = model
      _id = id
      _site = site
      
      # remove all instance variables and re-initialise after retrieving the record's document again
      instance_variables.each {|var| remove_instance_variable(var)}
      initialize(_model, COLLECTION.find_one(_id: _id), _site)
    end
    
    def increment!(field, value=1, conditions={})
      raise Yodel::DestroyedRecord if @destroyed
      raise NameError unless @document.key?(field.to_s)
      return false if @new
      
      # atomic increment (amount can be negative)
      conditions = Plucky::CriteriaHash.new(conditions).to_hash
      result = COLLECTION.update({_id: id}.merge(conditions), {'$inc' => {field => value}}, safe: true)
      succeeded = result['n'] != 0
      
      # update the object cache, and indicate if the update was successful
      @document[field.to_s] += value if succeeded
      @typecast[field.to_s] += value if succeeded # FIXME: should pull the value through from_mongo
      succeeded
    end
    
    
    # ----------------------------------------
    # Equality
    # ----------------------------------------
    def eql?(other)
      other.respond_to?(:model_name) && other.model_name == self.model_name && other.id == self.id
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
      @all_fields ||= model.all_model_fields.merge(eigenmodel.each_with_object({}) {|field, hash| hash[field['name']] = field})
    end
    
    def each_field_with_options(obj=nil)
      all_fields.each do |name, options|
        yield OpenStruct.new(options), obj
      end
      obj
    end
    
    def field_options(name)
      options = all_fields[name]
      options.nil? ? nil : OpenStruct.new(options)
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
    def to_str;         "#<#{@model.name}: #{@document['_id']}>"; end
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
      @parent ||= model.unscoped.first(_id: @document['_parent_id'])
    end
    
    def parent=(parent_record)
      @document['_parent_id'] = parent_record.nil? ? nil : parent_record.id
      @parent = parent_record
    end
    
    # values are stored in the documents hash
    def method_missing(name, *args, &block)
      # Catch a "fun" ruby 1.9 implemention detail. Calls to flatten blindly call
      # to_ary on items in an array rather than checking it they really support
      # the method with respond_to? Catch, and raise the expected exception.
      raise NoMethodError if name == :to_ary
      
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
      
      raise Yodel::UnknownField, "Unknown field <#{field}> for action <#{name}>" unless @document.key?(field)
      
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
      @changed[field] || @typecast[field] || generate_unloaded_field(field)
    end
    
    def generate_unloaded_field(name)
      field = field_options(name)
      raise Yodel::UnknownField, "Unknown field <#{name}>" if field.nil?
      type = Object.module_eval(field.type)
      value = type.from_mongo(self, field, @document[name])
      @typecast[name] = value
    end
    
    def field_changed?(field)
      @changed.key?(field)
    end
    
    def field_was(field)
      @typecast[field]
    end
    
    def typecast_values
      each_field_with_options do |field|
        type = Object.module_eval(field.type)
        unless type.delay_load?
          value = type.from_mongo(self, field, @document[field.name])
          @typecast[field.name] = value
          @changed[field.name] = value if type.mutable?
        end
      end
    end
    
    def copy_mutable_values
      each_field_with_options({}) do |field, changed|
        type = Object.module_eval(field.type)
        if type.mutable?
          changed[field.name] = @typecast[field.name]
        end
      end
    end
    
    
    # ----------------------------------------
    # Conversions
    # ----------------------------------------
    def to_json
      fields = []
      values = {}
      
      each_field_with_options do |field, _|
        type = Object.module_eval(field.type)
        #unless field.display == false
          value = type.to_json(self, field, @document[field.name])
          values[field.name] = value
          fields << {name: field.name, type: field.type}
        #end
      end
      
      {
        id: id.to_s,
        parent_id: parent_id.nil? ? nil : parent_id.to_s,
        model: model_name,
        index: index,
        fields: fields,
        values: values
      }
    end
    
    def from_json(json)
      return unless json['fields']
      json['fields'].each do |json_field|
        json_field = OpenStruct.new(json_field)
        field = field_options(json_field.name)
        next if field.nil?
        
        if field.type == 'StoreMany' && !json_field.action.nil?
          value = model.unscoped.find(BSON::ObjectId.from_string(json_field.value))
          @changed[field.name] = get_field(field.name)
          
          if json_field.action == 'remove'
            @changed[field.name].delete(value)
          elsif json_field.action == 'add'
            @changed[field.name] << value unless @changed[field.name].include?(value)
          end
        else
          @changed[field.name] = Object.module_eval(field.type).from_json(self, field, json_field.value)
        end
      end
    end
    
    def to_form(url, options={})
      method = options.delete(:method) || 'post'
      only = options[:only].try(:collect, &:to_s)
      
      html = "<form action='#{url}' method='#{method}'>"
      each_field_with_options do |field|
        next unless only.nil? || only.include?(field.name)
        type = Object.module_eval(field.type)
        
        # FIXME: field.display is being overriden by Object#display
        unless field.display == false
          input = type.to_html_field(self, field, @document[field.name]).to_s
          if input
            html += "<p><label for='#{field.name}'>#{field.name.humanize}</label>#{input}</p>"
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
        field = field_options(name)
        next if field.nil?
        @changed[name] = Object.module_eval(field.type).from_html_field(self, field, value)
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
          before_completed = self.class._before_#{callback}_callbacks.dup
          self.class._before_#{callback}_callbacks.each {|method| send method}
          
          unless self.is_a?(Model)
            mixins.collect {|mixin| mixin.class._before_#{callback}_callbacks}.flatten.each do |callback|
              unless before_completed.include?(callback)
                send callback
                before_completed << callback
              end
            end
          end
        end
        
        def _run_after_#{callback}_callbacks
          after_completed = self.class._after_#{callback}_callbacks.dup
          self.class._after_#{callback}_callbacks.each {|method| send method}
          
          unless self.is_a?(Model)
            mixins.collect {|mixin| mixin.class._after_#{callback}_callbacks}.flatten.each do |callback|
              unless after_completed.include?(callback)
                send callback
                after_completed << callback
              end
            end
          end
        end
        
        def _run_#{callback}_callbacks(&block)
          _run_before_#{callback}_callbacks          
          yield if block_given?
          _run_after_#{callback}_callbacks
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
      true
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
      model.unscoped.where(_parent_id: id).order('index asc')
    end
        
    # Siblings of this record (other records with the same parent)
    def siblings
      unless parent_id.nil?
        model.unscoped.where(:_parent_id => parent_id, :_id.ne => id).order('index asc')
      else
        # A parent ID of nil indicates this record is the root of a tree. Since there
        # are multiple trees (including the model tree), a sibling query makes no sense.
        model.unscoped.where(:_id => id)
      end
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
      
      each_field_with_options do |field|
        # TODO: we should cache somewhere which types do and do not contain the search_terms_set
        # method; this can also be used to automatically populate the searchable option on fields
        type = Object.module_eval(field.type)
        next if field.searchable == false || !type.respond_to?(:search_terms_set)
        
        value = get_field(field.name)
        next if value.nil?
        search_terms.merge(type.search_terms_set(value).collect(&:downcase))
      end
      
      self.search_keywords = search_terms.to_a
    end
    
    private
      def perform_save
        # merge the modified values back to the mongo document
        @changed.each do |name, value|
          field = field_options(name)
          @document[name] = Object.module_eval(field.type).to_mongo(self, field, value)
          @typecast[name] = value
        end
        
        # perform an update or insert of the raw values
        # FIXME: safe: true, and handle failed result
        COLLECTION.save(@document)
        
        # after a save there are no changed fields
        @changed = copy_mutable_values
      end
  end
end
