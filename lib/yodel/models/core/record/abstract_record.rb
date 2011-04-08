module Yodel
  class AbstractRecord
    attr_reader   :values, :typecast, :changed, :errors
    
    def initialize(values={})
      @new      = values.empty?
      @values   = default_values.merge(values)
      @typecast = {} # typecast versions of original document values
      @changed  = {} # typecast versions of changed values
    end
    
    
    # ----------------------------------------
    # Equality
    # ----------------------------------------
    def eql?(other)
      other.respond_to?(:id) && other.id == self.id &&
      other.class.name == self.class.name
    end
  
    alias :== :eql?

    def hash
      id.hash
    end
    
    
    # ----------------------------------------
    # Modelling
    # ----------------------------------------
    def fields
      {}
    end
  
    def field(name)
      fields[name]
    end
  
    def field?(name)
      fields.key?(name)
    end
  
    def default_values
      fields.each_with_object({}) {|(name, field), defaults| defaults[name] = field.default}
    end
    
    
    # ----------------------------------------
    # Representations
    # ----------------------------------------
    def inspect_hash
      fields.each_with_object({}) do |(name, field), hash|
        value = get(name)
        hash[name] = (value.respond_to?(:to_str) ? value.to_str : value.inspect)
      end
    end
    
    def inspect
      "#<#{self.class.name} #{inspect_hash.collect {|pair| pair.join(': ')}.join(', ')}>"
    end
  
    def to_str
      "#<#{self.class.name}: #{id}>"
    end
    
    alias :to_s :to_str
  
    def to_json(*a)
      @values.to_json(*a)
    end
  
    def from_json(values)
      values.each do |name, value|
        ensure_field_is_valid(name)
        current_field = field(name)
        
        # action hashes allow operations on fields such as append, increment
        if value.is_a?(Hash) && value.key?(:_action) && value.key?(:_value)
          current_field.json_action(value.delete(:_action), value.delete(:_value), self)
        else
          current_field.from_json(value, self)
        end
      end
    
      save
    end
  
  
    # ----------------------------------------
    # Accessors
    # ----------------------------------------
    def id
      object_id
    end
  
    def get(name)
      ensure_field_is_valid(name)
      return @changed[name] if @changed.key?(name)
      return @typecast[name] if @typecast.key?(name)
      typecast_value(name)
    end
  
    def get_raw(name)
      ensure_field_is_valid(name)
      @values[name]
    end
  
    def set(name, value)
      ensure_field_is_valid(name)
      @changed[name] = value
    end
    
    def set_raw(name, value)
      ensure_field_is_valid(name)
      @values[name] = value
      @changed.delete(name)
      @typecast.delete(name)
    end
  
    def present?(name)
      ensure_field_is_valid(name)
      !get(name).blank?
    end
  
    def changed?(name)
      ensure_field_is_valid(name)
      @changed.key?(name)
    end
    
    def changed!(name)
      ensure_field_is_valid(name)
      @changed[name] = get(name)
    end
  
    def field_was(name)
      ensure_field_is_valid(name)
      @typecast[name]
    end
    
    def increment!(name, value=1)
      ensure_field_is_valid(name)
      current = get(name)
      set(name, current + value)
      save_without_validation
    end
  
    def method_missing(name, *args, &block)
      # Catch a "fun" ruby 1.9 implemention detail. Calls to flatten blindly call
      # to_ary on items in an array rather than checking it they really support
      # the method with respond_to? Catch, and raise the expected exception.
      raise NoMethodError if name == :to_ary    
      field_name = name.to_s
    
      if field_name.end_with?('_changed?')
        changed?(field_name[0...-9])
      elsif field_name.end_with?('=')
        set(field_name[0...-1], args.first)
      elsif field_name.end_with?('?')
        present?(field_name[0...-1])
      elsif field_name.end_with?('_was')
        field_was(field_name[0...-4])
      else
        get(field_name)
      end
    end
  
  
    # ----------------------------------------
    # Persistence
    # ----------------------------------------
    def new?
      !!@new
    end
  
    def destroyed?
      !!@destroyed
    end
    
    def save
      valid? ? save_without_validation : false
    end

    def save_without_validation
      raise Yodel::DestroyedRecord if destroyed?
      succeeded = false
    
      run_save_callbacks do
        send("run_#{new? ? 'create' : 'update'}_callbacks") do
          @changed.each do |name, value|
            @values[name] = field(name).untypecast(value, self)
            @typecast[name] = value
          end
          succeeded = perform_save
        end
      end
      
      if succeeded
        @new = false
        @changed = {}
      end
      succeeded
    end
  
    def destroy
      return if new? || destroyed?
      succeeded = false
      run_destroy_callbacks do
        succeeded = perform_destroy
      end
      @destroyed = succeeded
    end
  
    def update(values, do_save=true)
      raise Yodel::DestroyedRecord if destroyed?
      values.each do |name, value|
        if field(name).protected?
          raise Yodel::MassAssignment, "Cannot mass assign #{field}"
        else
          set(name, value)
        end
      end    
      save if do_save
    end
  
    def reload
      return if new? || destroyed?
      _id = id
      
      # remove all instance variables and re-initialise
      instance_variables.each {|var| remove_instance_variable(var)}
      perform_reload(_id)
    end
  
  
    # ----------------------------------------
    # Callbacks & Validation
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
      
        def run_before_#{callback}_callbacks
          self.class._before_#{callback}_callbacks.each {|method| send method}
        end
      
        def run_after_#{callback}_callbacks
          self.class._after_#{callback}_callbacks.each {|method| send method}
        end
      
        def run_#{callback}_callbacks(&block)
          run_before_#{callback}_callbacks          
          yield if block_given?
          run_after_#{callback}_callbacks
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
      valid = false
      run_validation_callbacks do
        @errors = Hash.new {|hash, key| hash[key] = []}    
        @changed.each {|name, value| field(name).validate(value, self, errors)}
        valid = @errors.empty?
      end
      valid
    end
  
  
    private
      def ensure_field_is_valid(name)
        raise Yodel::UnknownField, "Unknown field <#{name}>" unless field?(name)
      end
    
      def typecast_value(name)
        value = field(name).typecast(@values[name], self)
        @typecast[name] = value
      end
  end
end
