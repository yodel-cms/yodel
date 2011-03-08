module Yodel
  class Model
    include ::MongoMapper::Document
    plugin  MongoMapper::Plugins::InheritedSci
    
    has_many :children, class: Yodel::Model, dependent: :destroy, order: 'index asc', foreign_key: 'parent_id'
    belongs_to :parent, class: Yodel::Model
    belongs_to :site, class: Yodel::Site
    ensure_index 'parent_id'
    ensure_index 'site_id'
    
    key :index, Integer, required: true, default: nil
    key :parent_id, BSON::ObjectId, default: nil
    key :site_id, BSON::ObjectId, default: nil
    
    # yodel_search_keywords is a list of keywords (strings) which will match this record
    # by default split all string keys (with !searchable false) and remove all non word
    # characters. sub-classes should override this method if different functionality req.
    key :yodel_search_keywords, Array, index: true, display: false


    # ----------------------------------------
    # Hierarchical methods
    # ----------------------------------------
    # insertion and deletion to maintin the integrity of the 'index' field
    before_validation_on_create :append_to_siblings
    before_destroy :remove_from_siblings    
    
    def append_to_siblings
      highest_index = self.siblings.last.try(:index) || 0
      self.index = highest_index + 1
    end

    # FIXME: these need to be atomic ops
    def insert_in_siblings(index)
      remove_from_siblings if self.index
      self.siblings.where(:index.gte => index).each do |sibling|
        sibling.update_attributes(index: sibling.index + 1)
      end
      record.index = index
    end

    def remove_from_siblings
      self.siblings.where(:index.gte => self.index).each do |sibling|
        sibling.update_attributes(index: sibling.index - 1)
      end
      self.index  = nil
      self.parent = nil
    end
    
    # Scope to retrieve all records of a model type under a site e.g
    # Yodel::Layout.all_for(site) returns all layout records
    scope :all_for, lambda {|site| where(site_id: site.id)}
    
    # Scope to retrieve all root records of a model type under a site, e.g
    # Yodel::Groups.roots(site). Returns all records with a nil parent.
    scope :roots, lambda {|site| where(site_id: site.id, parent_id: nil).order('index asc')}
    
    # Scope to retrieve the first (or only) root record of a model under a
    # site, e.g Yodel::Page.root(site) will retrieve the root page of a site
    scope :root, lambda {|site| where(site_id: site.id, parent_id: nil).limit(1).order('index asc')}
    
    # Siblings of this record (other records with the same parent)
    def siblings
      self.class.where(parent_id: self.parent_id).order('index asc')
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
      self.parent_id.nil?
    end
    
    # Use to define acceptable children for a model type. For instance, blogs
    # should only allow articles as children: allowed_descendants Article
    def self.allowed_descendants(*args)
      @allowed_descendants = args
    end

    # Returns an array of all allowed descendants, and all descendants of
    # those types. If no call to allowed_descendants has been made, nil
    # will be returned instead (indicating there are no allowed descendants).
    def self.all_allowed_descendants
      @all_allowed_descendants ||= @allowed_descendants.try(:collect) {|type| type.descendants + [type]}
    end
    
    
    
    # ----------------------------------------
    # Full text search
    # ----------------------------------------
    # Override to hide or display records in search results. This is an instance method
    # so individual records can be included/excluded as needed.
    def show_in_search?
      true
    end
    
    # Name to display a user in search results. Allows the name and search result names
    # of a record to be different. e.g 'Some blog post' vs 'News: Some blog post'.
    def search_title
      name
    end
    
    # Before every save, the list of search keywords for a record is updated
    # FIXME: remove things like layouts from search
    before_save :update_search_keywords
    def update_search_keywords
      return unless self.class.searchable?
      search_terms = Set.new
      self.class.keys.values.each do |key|
        next if key.name.starts_with?('_') || key.options[:searchable] == false || key.type.nil? || !key.type.instance_methods.include?(:search_terms_set)
        (self.send(key.name) || '').search_terms_set.each do |term|
          search_terms << term.downcase
        end
      end
      self.yodel_search_keywords = search_terms.to_a
    end
    
    # Performs a search using the supplied query over all records of this model type or
    # children on this model. If you would like to search all models, call on Yodel::Model.
    def self.search(query)
      # TODO
    end
    
    # Specify whether this model type will appear in
    # search results and have search keywords updated
    def self.searchable(searchable)
      @searchable = searchable
    end
    
    # Indicates whether this model type will be returned
    # in search results and have search keywords updated.
    def self.searchable?
      @searchable.nil? ? true : @searchable
    end
    
    
    
    # ----------------------------------------
    # Admin interface options
    # ----------------------------------------
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
    
    # Specify whether the admin interface shows child
    # elements of this record in a separate tree. For
    # instance, all shop related records would be shown
    # under a shop tree separate to the main page tree.
    def self.menu_root(menu_root)
      @menu_root = menu_root
    end
    
    def self.menu_root?
      @menu_root.nil? ? false : @menu_root
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

    # some types may or may not allow more than one root per site, and may or
    # may not be able to act as a root for a site at all
    def self.single_root
      @single_root = true
    end

    def self.single_root?
      @single_root
    end

    
    # Copy class instance attributes down the inheritance chain
    def self.inherited(child)
      super(child)
      child.instance_variable_set('@single_root', @single_root)
      child.instance_variable_set('@allowed_descendants', @allowed_descendants)
    end
    

    
    # FIXME: this needs to be extracted out to the different key types?
    # def self.cleanse_hash(hash)
    #   # for readability rename '_id' to 'id',
    #   # and '_type' to 'type'
    #   if hash.has_key?('_id')
    #     id = hash.delete('_id')
    #     hash['id'] = id.to_s
    #   end
    #   if hash.has_key?('_type')
    #     type = hash.delete('_type')
    #     hash['type'] = type
    #   end
    #   
    #   # we don't need to store which site the record belongs to
    #   hash.delete('site_id')
    #   
    #   # or the search keywords that are generated
    #   hash.delete('yodel_search_keywords') if hash.has_key?('yodel_search_keywords')
    #   
    #   # attributes starting with an underscore are private
    #   hash.delete_if {|key, value| key.start_with? '_'}
    #   
    #   # change all references (values of type ObjectID)
    #   # to a string of the object ID, cleanse embedded
    #   # documents, remove "_id" from all keys, and change
    #   # date and time values in to a format suitable for
    #   # clients to read appropriately
    #   hash.each do |key, value|
    #     hash[key] = value.to_s if value.is_a?(BSON::ObjectId)
    #     hash[key] = cleanse_hash(value) if value.is_a?(Hash)
    #     hash[key] = value.force_encoding("UTF-8") if value.is_a?(String)
    #     
    #     if self.keys[key.to_sym].try(:type) && self.keys[key.to_sym].type.ancestors.include?(Tags)
    #       hash[key] = Tags.new(value).to_s
    #       next
    #     end
    #     
    #     if key.end_with?('_id')
    #       hash.delete(key)
    #       value_key = key.gsub('_id', '')
    #       hash[value_key] = value unless hash.has_key?(value_key)
    #       next
    #     end
    #     
    #     # hack to get around mongo mapper mapping all dates to time objects...
    #     if value.is_a?(Time) || value.is_a?(Date)
    #       if self.keys.has_key?(key) && !self.keys[key].type.nil?
    #         type = self.keys[key].type
    #       else
    #         type = value.class
    #       end
    #     
    #       if type.ancestors.include?(Date)
    #         hash[key] = value.strftime("%d %b %Y")
    #       elsif type.ancestors.include?(Time)
    #         # FIXME: this is just horrible.... only done to make the admin interface easy
    #         hash.delete(key)
    #         hash[key + '_date'] = value.strftime("%d %b %Y")
    #         hash[key + '_hour'] = value.localtime.hour
    #         hash[key + '_min']  = value.localtime.min
    #       end
    #       next
    #     end
    #     
    #     # has_many associations stored in an array need
    #     # to have ObjectID's converted to strings
    #     if value.is_a?(Array)
    #       hash[key] = value.collect do |val|
    #         val.is_a?(BSON::ObjectId) ? val.to_s : val
    #       end
    #     end
    #   end
    #   
    #   hash
    # end
    # 
    # def to_json_hash
    #   self.class.cleanse_hash(attributes)
    # end
    
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
    
    # def self.default_values_to_json_hash
    #       cleanse_hash(default_values)
    #     end
  end  
end
