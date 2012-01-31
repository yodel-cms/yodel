# Record objects must implement these methods:
# fields
# perform_save
# perform_destroy
# perform_reload

class AbstractRecord
  attr_reader   :values, :typecast, :changed, :errors, :stash
  
  def initialize(values={}, new_record=true)
    @values   = default_values.merge(values.stringify_keys) # FIXME: don't merge here; default || values
    @typecast = {} # typecast versions of original document values
    @changed  = {} # typecast versions of changed values
    @stash    = {} # values of unknown fields set by from_json
    @errors   = Errors.new
    @new      = new_record
  end
  
  
  # ----------------------------------------
  # Equality
  # ----------------------------------------
  def eql?(other)
    other.respond_to?(:id) && other.id == self.id &&
    other.is_a?(AbstractRecord)
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
    fields.each_with_object({}) do |(name, field), defaults|
      default_value = field.default
      unless default_value.nil? && field.strip_nil?
        defaults[name] = default_value
      end
    end
  end
  
  
  # ----------------------------------------
  # Representations
  # ----------------------------------------
  def inspect_hash
    fields.each_with_object({}) do |(name, field), hash|
      hash[name] = get(name)
    end
  end
  
  def inspect
    values = inspect_hash.collect do |name, value|
      if value.is_a?(Array) || value.is_a?(ChangeSensitiveArray)
        value = "[#{value.collect {|element| inspect_value(element)}.join(', ')}]"
      elsif value.is_a?(Hash) || value.is_a?(ChangeSensitiveHash)
        value = "{#{value.to_hash.collect {|key, value| "#{key.to_s}: #{inspect_value(value)}"}.join(', ')}}"
      else
        value = inspect_value(value)
      end
      "#{name}: #{value}"
    end
    "#<#{self.class.name} #{values.join(', ')}>"
  end
  
  def inspect_value(value)
    value.respond_to?(:to_str) && !value.is_a?(String) ? value.to_str : value.inspect.to_s
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
      if field?(name)
        current_field = field(name)
        raise MassAssignment, "Cannot mass assign #{field}" if current_field.protected?
      else
        @stash[name] = value
        next
      end
      
      # action hashes allow operations on fields such as append, increment
      if value.is_a?(Hash) && value.key?('_action')
        current_field.json_action(value.delete('_action'), value.delete('_value'), self)
      else
        catch :ignore_value do
          processed_value = current_field.from_json(value, self)
          set(name, processed_value)
        end
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
  
  def clear_key(name)
    @changed.delete(name)
    @typecast.delete(name)
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
  
  def get_meta(name)
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
  
  def set_meta(name, value)
    @values[name] = value
  end
  
  def present?(name)
    # FIXME: this doesn't work for many/one store: false
    ensure_field_is_valid(name)
    !get(name).blank?
  end

  def changed?(name)
    ensure_field_is_valid(name)
    @changed.key?(name)
  end
  
  def changed!(name)
    ensure_field_is_valid(name)
    return if @changed.key?(name)
    @changed[name] = get(name).dup
  end

  def field_was(name)
    ensure_field_is_valid(name)
    if @typecast.key?(name)
      @typecast[name]
    else
      typecast_value(name)
    end
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
    raise DestroyedRecord if destroyed?
    callback = "run_#{new? ? 'create' : 'update'}_callbacks"
    succeeded = false
    
    run_save_callbacks do
      send(callback) do
        
        # untypecast all changed values to construct an up to date values hash
        changed.each do |name, value|
          changed_field = field(name)
          untypecast_value = changed_field.untypecast(value, self)
          if untypecast_value.nil? && changed_field.strip_nil?
            values.delete(name)
          else
            values[name] = untypecast_value
          end
          typecast[name] = value
        end
        
        succeeded = perform_save
      end
    end
    
    if succeeded
      @new = false
      @changed.clear
      @stash.clear
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
    raise DestroyedRecord if destroyed?
    return if values.empty?
    values.stringify_keys!
    values.each do |name, value|
      ensure_field_is_valid(name)
      if field(name).protected?
        raise MassAssignment, "Cannot mass assign #{field}"
      else
        set(name, value)
      end
    end
    save if do_save
  end

  def reload
    return if new? || destroyed?
    reload_params = prepare_reload_params
    
    # remove all instance variables and re-initialise
    instance_variables.each {|var| remove_instance_variable(var)}
    perform_reload(reload_params)
  end
  
  def prepare_reload_params
    {id: id}
  end


  # ----------------------------------------
  # Callbacks & Validation
  # ----------------------------------------
  CALLBACKS = %w{save create update destroy validation}
  ORDERS    = %w{before after}
  CALLBACKS.each do |callback|
    ORDERS.each do |order|
      eval "
        @_#{order}_#{callback}_callbacks = []

        def self._#{order}_#{callback}_callbacks
          @_#{order}_#{callback}_callbacks
        end

        def self.#{order}_#{callback}(*callbacks)
          @_#{order}_#{callback}_callbacks += callbacks
        end

        def run_#{order}_#{callback}_callbacks
          self.class._#{order}_#{callback}_callbacks.each {|method| send method}
        end
      "
    end
    
    eval "
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
      ORDERS.each do |order|
        callbacks = instance_variable_get("@_#{order}_#{callback}_callbacks")
        child.instance_variable_set("@_#{order}_#{callback}_callbacks", callbacks)
      end
    end
  end

  def valid?
    # validate all fields for new records; we know saved records should be
    # valid so we can limit testing to the set of changed fields only
    run_validation_callbacks do
      @errors.clear
      unless new?
        @changed.each {|name, value| field(name).validate(self, @errors)}
      else
        fields.each {|name, field| field.validate(self, @errors)}
      end
    end
    @errors.empty?
  end
  
  def errors?
    !@errors.blank?
  end
  
  # Field callbacks
  FIELD_CALLBACKS = %w{save create update destroy}
  FIELD_CALLBACKS.each do |callback|
    ORDERS.each do |order|
      eval "
        #{order}_#{callback} :trigger_field_#{order}_#{callback}_callbacks
        def trigger_field_#{order}_#{callback}_callbacks
          trigger_field_callback(:#{order}, :#{callback})
        end
      "
    end
  end
  
  def trigger_field_callback(order, action)
    method = "#{order}_#{action}"
    fields.each do |name, field|
      field.send(method, self) if field.respond_to?(method)
    end
  end
  
  
  # ----------------------------------------
  # Search
  # ----------------------------------------
  def search_terms
    search_terms = Set.new
    
    fields.each do |name, field|
      # TODO: we should cache somewhere which types do and do not contain the search_terms_set
      # method; this can also be used to automatically populate the searchable option on fields
      next unless field.searchable? && field.respond_to?(:search_terms_set)
      search_terms.merge(field.search_terms_set(self).collect(&:downcase))
    end
    
    search_terms.to_a
  end
  
  
  private
    def ensure_field_is_valid(name)
      raise UnknownField, "Unknown field <#{name}>" unless field?(name)
    end
  
    def typecast_value(name)
      value = field(name).typecast(@values[name], self)
      @typecast[name] = value
    end
end
