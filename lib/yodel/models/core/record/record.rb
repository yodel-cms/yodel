module Yodel
  class Record < Yodel::SiteRecord
    collection    :records
    attr_reader   :model_record, :mixins
    attr_accessor :real_record

    def initialize(model, site, values={})
      @model_record = model
      @site = site
      @model  = load_model(model, values)
      @mixins = create_mixin_instances(values)
      super(site, values)

      # mixins have their db access methods delegated to the "real record"
      # (the main object representing the mongo document). To maintain a
      # transparency between objects, key instance variables in the mixin
      # are changed to refer to the same instance variables in the real record.
      delegate_mixins
    end

    def to_str
      "#<#{model.name}: #{id}>"
    end
    
    def default_values
      super.merge({'model' => model_record.id})
    end
    
    def collection
      Yodel::Record.collection
    end    
    
    
    # ----------------------------------------
    # Permissions
    # ----------------------------------------
    def user_allowed_to?(user, action)
      model.user_allowed_to?(user, action, model)
    end
  
    def user_allowed_to_view?(user)
      model.user_allowed_to?(user, :view, model)
    end
  
    def user_allowed_to_update?(user)
      model.user_allowed_to?(user, :update, model)
    end
  
    def user_allowed_to_delete?(user)
      model.user_allowed_to?(user, :delete, model)
    end
  
    def user_allowed_to_create?(user)
      model.user_allowed_to?(user, :create, model)
    end

    
    # ----------------------------------------
    # Modelling
    # ----------------------------------------
    def fields
      @fields ||= @model.all_record_fields
    end
    
    def inspect_hash
      {model: model_record, parent: parent, index: index}.merge(super)
    end
  
    def load_model(model, values)
      if values['eigenmodel'].nil?
        model
      else
        model # fixme: load eigenmodel
      end
    end
  
    def create_mixin_instances(values)
      return [] if @model.nil?
      @model.mixins.collect do |model_id|
        mixin_model = site.models.find(model_id)
        mixin_model.record_class.new(mixin_model, values, site)
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
    
    def default_child_model
      model.default_child_model
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
      siblings.where(:index.gte => new_index).each do |sibling|
        sibling.increment!(:index)
      end
      self.index = new_index
    end

    def remove_from_siblings
      siblings.where(:index.gte => index).each do |sibling|
        sibling.increment!(:index, -1)
      end
      self.index = nil
      self.parent = nil
    end
    
    # Children of this record (other records which have this record as a parent)
    def children
      model.unscoped.where(parent: id).order('index asc')
    end
        
    # Siblings of this record (other records with the same parent)
    def siblings
      unless parent.nil?
        model.unscoped.where(:parent => get_raw('parent'), :_id.ne => id).order('index asc')
      else
        # A parent ID of nil indicates this record is the root of a tree. Since there
        # are multiple trees (including the model tree), a sibling query makes no sense.
        model.unscoped.where(:nonexistant_field => 'true')
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
      parent.nil?
    end
    
    
    # ----------------------------------------
    # Search
    # ----------------------------------------
    before_save :update_search_keywords
    def update_search_keywords
      return unless model.searchable?
      search_terms = Set.new
      
      fields.each do |name, field|
        # TODO: we should cache somewhere which types do and do not contain the search_terms_set
        # method; this can also be used to automatically populate the searchable option on fields
        next unless field.searchable? && field.respond_to?(:search_terms_set)
        search_terms.merge(field.search_terms_set(get(field.name)).collect(&:downcase))
      end
      
      self.search_keywords = search_terms.to_a
    end
  end
end
