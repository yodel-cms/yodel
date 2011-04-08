module Yodel
  class Record < MongoModel
    collection    'records'
    attr_reader   :model, :mixins
    attr_accessor :real_record

    def initialize(model, site, values={})
      @site = site
      @model  = create_eigenmodel(model, values)
      @mixins = create_mixin_instances(values)
      super(site, values)

      # mixins have their db access methods delegated to the "real record"
      # (the main object representing the mongo document). To maintain a
      # transparency between objects, key instance variables in the mixin
      # are changed to refer to the same instance variables in the real record.
      delegate_mixins
    end

    def to_str
      "#<#{self.model.name}: #{id}>"
    end

    
    # ----------------------------------------
    # Modelling
    # ----------------------------------------
    def fields
      model.all_record_fields
    end
    
    def default_values
      { '_model' => model.name,
        '_parent_id' => nil,
        '_index' => nil,
        '_eigenmodel' => []
      }.merge(super)
    end
    
    def inspect_hash
      {model: model_name, parent: parent_id, index: index}.merge(super)
    end
  
    def create_eigenmodel(model, values)
      if values.key?('_eigenmodel') && !values['_eigenmodel'].empty?
        model # FIXME: generate once off model instance for this record
      else
        model
      end
    end
  
    def create_mixin_instances(values)
      return [] if model.nil?
      model.mixins.collect do |model_name|
        mixin_model = site.model(model_name)
        mixin_model.klass.new(mixin_model, values, site)
      end.compact
    end
  
    def delegate_mixins
      extend SingleForwardable
      ancestors = self.class.ancestors
      included_classes = []
    
      mixins.each_with_index do |mixin, index|
        # reassign the mixin object's instance vars
        %w{@model @new @site @values @typecast @changed}.each do |var|
          mixin.instance_variable_set(var, instance_variable_get(var))
        end
      
        # delegate database access to the main object
        mixin.extend SingleForwardable
        mixin.real_record = self
        mixin.def_delegators :@real_record, :save, :save_without_validation, :destroy, :update,
                                            :reload, :all_fields, :to_json, :from_json
      
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
        
    # def add_field(name, type, options={})
    #   name = name.to_s
    #   Yodel::Model.add_field(name, type, eigenmodel, options)
    #   @document[name] = options['default'] || options[:default]
    #   @typecast[name] = type.from_mongo(self, name, @document[name])
    # end
    # 
    # def remove_field(name)
    #   Yodel::Model.remove_field(name, eigenmodel)
    #   @document.delete(name)
    #   @typecast.delete(name)
    #   @changed.delete(name)
    # end
    
    
    # ----------------------------------------
    # Accessors
    # ----------------------------------------
    def model_name;     @values['_model']; end
    def parent_id=(i);  @values['_parent_id'] = i; end
    def parent_id;      @values['_parent_id']; end
    def index=(i);      @values['_index'] = i; end
    def index;          @values['_index']; end
    
    # parent acts as an association
    def parent
      return nil if model.nil?
      @parent ||= model.unscoped.first(_id: @values['_parent_id'])
    end
    
    def parent=(parent_record)
      @values['_parent_id'] = parent_record.nil? ? nil : parent_record.id
      @parent = parent_record
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

    # FIXME: these need to be atomic ops over the whole set of children
    def insert_in_siblings(new_index)
      remove_from_siblings if index
      siblings.where(:_index.gte => new_index).each do |sibling|
        sibling.increment!(:_index)
      end
      self.index = new_index
    end

    def remove_from_siblings
      siblings.where(:_index.gte => index).each do |sibling|
        sibling.increment!(:_index, -1)
      end
      self.index = nil
      self.parent = nil
    end
    
    # Children of this record (other records which have this record as a parent)
    def children
      model.unscoped.where(_parent_id: id).order('_index asc')
    end
        
    # Siblings of this record (other records with the same parent)
    def siblings
      unless parent_id.nil?
        model.unscoped.where(:_parent_id => parent_id, :_id.ne => id).order('_index asc')
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
      return unless model.searchable?
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
  end
end
