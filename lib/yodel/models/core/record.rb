module Yodel
  class Record
    include ::MongoMapper::Document
    plugin  MongoMapper::Plugins::InheritedSci
    #include Yodel::Hierarchical
    extend  Yodel::Searchable
    
    
      belongs_to :parent, class: Yodel::Record
      has_many :children, class: Yodel::Record, dependent: :destroy, order: 'index asc', foreign_key: 'parent_id'
      key :index, Integer, required: true, default: nil
      ensure_index 'parent_id'

      scope :roots, lambda {|site| where(site_id: site.id, parent_id: nil).order('index asc')}

      def all_children
        @all_children ||= children + children.inject([]) {|records, child| records + child.all_children}
      end

      def siblings
        @siblings ||= self.where(parent_id: self.parent_id).order('index asc')
      end

      def parents
        @parents ||= [self] + (self.parent.try(:parents) || [])
      end

      def root?
        defined?(@parent_id) && !@parent_id.nil?
      end


      # insertion and deletion to maintin the integrity of the 'index' field
      before_destroy :remove_from_parent
      def remove_from_parent
        if root?
          remove_from_root
        else
          self.parent.remove_child(self)
        end
      end

      before_validation_on_create :add_to_parent
      def add_to_parent
        if root?
          append_to_root
        else
          self.parent.append_child(self)
        end
      end

      # FIXME: need to do extra checks; e.g append_to_root needs
      # to check if parent and index are set, and if so remove the
      # record from the existing collection
      def append_child(child)
        append_to_siblings(children, child)
        child.parent = self
      end

      def append_to_root
        append_to_siblings(self.class.roots_for_site(self.site), self)
        self.parent = nil
      end

      def append_to_siblings(siblings, record)
        highest_index = siblings.last.try(:index) || 0
        record.index = highest_index + 1
      end

      def insert_child(child, index)
        insert_in_siblings(children, child, index)
        child.parent = self
      end

      def insert_in_root(index)
        insert_in_siblings(self.class.roots_for_site(self.site), self, index)
        self.parent = nil
      end

      def insert_in_siblings(siblings, record, index)
        if record.index
          record.parent.remove_child(child) if !root?
          record.remove_from_root if root?
        end

        siblings.each do |sibling|
          if sibling.index >= index
            sibling.index += 1
            sibling.save
          end
        end
        record.index = index
      end

      def remove_child(child)
        remove_from_siblings(children, child)
      end

      def remove_from_root
        remove_from_siblings(self.class.roots_for_site(self.site), self)
      end

      def remove_from_siblings(siblings, record)
        siblings.each do |sibling|
          if sibling.index > record.index
            sibling.index -= 1
            sibling.save
          end
        end
        record.index  = nil
        record.parent = nil
      end

      def move_to(new_index)
        if root?
          remove_from_root
          insert_in_root(new_index)
        else
          self.parent.remove_child(self)
          self.parent.insert_child(self, new_index)
        end
      end


      # it's sometimes necessary to restrict the type of records which can appear
      # below a record of a certain type. override these methods as necessary
      def self.allowed_child_types(*args, &block)
        if block_given?
          @allowed_child_types = yield
        elsif args.length >= 1 && !args.first.nil?
          @allowed_child_types = args
        elsif args.length == 1 && args.first.nil?
          @allowed_child_types = nil
        else
          # conditional assignment will trigger when a value is nil. since this
          # is an acceptable value for child types, we check if the types have
          # been defined yet, and if so return, otherwise assign descendants of
          # this type by default. contrast to:
          # @allowed_child_types ||= descendants
          # the list is ORd with an empty list so enumeration can be guaranteed
          if defined?(@allowed_child_types)
            @allowed_child_types || []
          else
            @allowed_child_types = self_and_descendants
          end
        end
      end

      def self.allowed_child_types_and_descendants
        unless @allowed_child_types_and_descendants
          @allowed_child_types_and_descendants = allowed_child_types.collect do |child_type|
            [child_type, *child_type.descendants]
          end.flatten
        end
        @allowed_child_types_and_descendants
      end


      # some types may or may not allow more than one root per site, and may or
      # may not be able to act as a root for a site at all
      def self.multiple_roots?
        !@single_root
      end

      def self.single_root
        @single_root = true
      end

      def self.single_root?
        @single_root
      end

      # copy class instance attributes down the inheritance chain
      def self.inherited(child)
        super(child)
        child.instance_variable_set('@single_root', @single_root)
        child.instance_variable_set('@allowed_child_types', @allowed_child_types)
      end
    
    
    set_collection_name 'record'
    belongs_to :site, class: Yodel::Site
    ensure_index 'site_id'
    
    def self.self_and_descendants
      [self] + self.descendants
    end
    
    def self.self_and_all_descendants
      types = Set[self]
      self.descendants.each do |child|
        types << child
        types.merge child.descendants
      end
      types.to_a
    end
    
    
    # when records are referred to via an association,
    # they need to be able to respond with a human
    # readable name. this method should be overriden.
    def name
      self._id.to_s
    end
    
    # An icon representing this record type. Should
    # be overriden by subclasses.
    def self.icon
      '/admin/images/default_icon.png'
    end
    
    # Returns a list of the tabs used for the keys of
    # this record. Tabs include 'Behaviour', 'SEO' etc.
    def self.tabs
      unless @tabs
        tabs = Set.new([nil])
        keys.each {|key| @tabs << key.options[:tab]}
        associations.each {|assoc| @tabs << assoc.options[:tab]}
        @tabs = tabs.to_a
      end
      @tabs
    end
    
    # FIXME: this needs to be extracted out to the different key types?
    def self.cleanse_hash(hash)
      # for readability rename '_id' to 'id',
      # and '_type' to 'type'
      if hash.has_key?('_id')
        id = hash.delete('_id')
        hash['id'] = id.to_s
      end
      if hash.has_key?('_type')
        type = hash.delete('_type')
        hash['type'] = type
      end
      
      # we don't need to store which site the record belongs to
      hash.delete('site_id')
      
      # or the search keywords that are generated
      hash.delete('yodel_search_keywords') if hash.has_key?('yodel_search_keywords')
      
      # attributes starting with an underscore are private
      hash.delete_if {|key, value| key.start_with? '_'}
      
      # change all references (values of type ObjectID)
      # to a string of the object ID, cleanse embedded
      # documents, remove "_id" from all keys, and change
      # date and time values in to a format suitable for
      # clients to read appropriately
      hash.each do |key, value|
        hash[key] = value.to_s if value.is_a?(BSON::ObjectId)
        hash[key] = cleanse_hash(value) if value.is_a?(Hash)
        hash[key] = value.force_encoding("UTF-8") if value.is_a?(String)
        
        if self.keys[key.to_sym].try(:type) && self.keys[key.to_sym].type.ancestors.include?(Tags)
          hash[key] = Tags.new(value).to_s
          next
        end
        
        if key.end_with?('_id')
          hash.delete(key)
          value_key = key.gsub('_id', '')
          hash[value_key] = value unless hash.has_key?(value_key)
          next
        end
        
        # hack to get around mongo mapper mapping all dates to time objects...
        if value.is_a?(Time) || value.is_a?(Date)
          if self.keys.has_key?(key) && !self.keys[key].type.nil?
            type = self.keys[key].type
          else
            type = value.class
          end
        
          if type.ancestors.include?(Date)
            hash[key] = value.strftime("%d %b %Y")
          elsif type.ancestors.include?(Time)
            # FIXME: this is just horrible.... only done to make the admin interface easy
            hash.delete(key)
            hash[key + '_date'] = value.strftime("%d %b %Y")
            hash[key + '_hour'] = value.localtime.hour
            hash[key + '_min']  = value.localtime.min
          end
          next
        end
        
        # has_many associations stored in an array need
        # to have ObjectID's converted to strings
        if value.is_a?(Array)
          hash[key] = value.collect do |val|
            val.is_a?(BSON::ObjectId) ? val.to_s : val
          end
        end
      end
      
      hash
    end
    
    def to_json_hash
      self.class.cleanse_hash(attributes)
    end
    
    def self.default_values
      {}.tap do |values|
        keys.each_value do |key|
          next unless !key.default_value.nil?
          values[key.name] =
            if key.default_value.respond_to?(:call)
              key.default_value.call
            else
              key.default_value
            end
        end
      end
    end
    
    def self.default_values_to_json_hash
      cleanse_hash(default_values)
    end
  end  
end
