require 'record/abstract_record'
require 'record/embedded_record'
require 'record/mongo_record'
require 'record/site_record'
require 'model/model'

class Record < SiteRecord
  collection    :records
  attr_reader   :model_record, :model, :mixins
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
    "#<#{model_record.name}: #{id}>"
  end
  
  def default_values
    super.merge({'model' => model.id})
  end
  
  def collection
    Record.collection
  end
  
  def perform_reload(params)
    document = load_mongo_document(_id: params[:id])
    initialize(params[:model], params[:site], document)
  end
  
  def prepare_reload_params
    super.tap {|vals| vals[:model] = @model}
  end
  
  
  # ----------------------------------------
  # Permissions
  # ----------------------------------------
  def user_allowed_to?(user, action)
    model.user_allowed_to?(user, action, self)
  end

  def user_allowed_to_view?(user)
    model.user_allowed_to?(user, :view, self)
  end

  def user_allowed_to_update?(user)
    model.user_allowed_to?(user, :update, self)
  end

  def user_allowed_to_delete?(user)
    model.user_allowed_to?(user, :delete, self)
  end

  def user_allowed_to_create?(user)
    model.user_allowed_to?(user, :create, self)
  end

  
  # ----------------------------------------
  # Modelling
  # ----------------------------------------
  def fields
    @fields ||= @model.all_record_fields
  end
  
  def inspect_hash
    {model: model, parent: parent, index: index}.merge(super)
  end

  def load_model(model, values)
    return model if values['eigenmodel'].nil?
    eigenmodel = site.models.find(values['eigenmodel'])
    values['eigenmodel'] = nil if eigenmodel.nil?
    eigenmodel || model
  end
  
  def create_eigenmodel
    return eigenmodel if eigenmodel?
    new_eigenmodel = model.create_model("#{id}_eigenmodel")
    self.eigenmodel = new_eigenmodel
    @model = new_eigenmodel
    save
  end
  
  def remove_eigenmodel
    eigenmodel.destroy if eigenmodel?
    self.eigenmodel = nil
    save
  end

  def create_mixin_instances(values)
    return [] if @model.nil?
    @model.mixins.collect do |mixin_model|
      mixin_model.record_class.new(mixin_model, site, values)
    end.compact
  end

  def delegate_mixins
    extend SingleForwardable
    ancestors = self.class.ancestors
    included_classes = []
  
    mixins.each_with_index do |mixin, index|
      # reassign the mixin object's instance vars
      %w{@model @new @site @values @typecast @changed @errors @stash}.each do |var|
        mixin.instance_variable_set(var, instance_variable_get(var))
      end
    
      # delegate database access to the main object
      mixin.extend SingleForwardable
      mixin.real_record = self
      mixin.def_delegators :@real_record, :save, :save_without_validation, :destroy, :update,
                                          :reload, :fields
    
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
  # Callbacks
  # ----------------------------------------
  # extend callbacks to work with mixins
  Model::CALLBACKS.each do |callback|
    Model::ORDERS.each do |order|
      eval "
        def run_#{order}_#{callback}_callbacks
          #{order}_completed = self.class._#{order}_#{callback}_callbacks.dup
          super
        
          mixins.collect {|mixin| mixin.class._#{order}_#{callback}_callbacks}.flatten.each do |callback|
            unless #{order}_completed.include?(callback)
              send callback
              #{order}_completed << callback
            end
          end
        end
      "
    end
  end
  
  before_validation :run_record_before_validation_callbacks
  def run_record_before_validation_callbacks
    model.run_record_before_validation_callbacks(self)
  end

  after_validation :run_record_after_validation_callbacks
  def run_record_after_validation_callbacks
    model.run_record_after_validation_callbacks(self)
  end

  before_save :run_record_before_save_callbacks
  def run_record_before_save_callbacks
    model.run_record_before_save_callbacks(self)
  end

  after_save :run_record_after_save_callbacks
  def run_record_after_save_callbacks
    model.run_record_after_save_callbacks(self)
  end

  before_create :run_record_before_create_callbacks
  def run_record_before_create_callbacks
    model.run_record_before_create_callbacks(self)
  end

  after_create :run_record_after_create_callbacks
  def run_record_after_create_callbacks
    model.run_record_after_create_callbacks(self)
  end

  before_update :run_record_before_update_callbacks
  def run_record_before_update_callbacks
    model.run_record_before_update_callbacks(self)
  end

  after_update :run_record_after_update_callbacks
  def run_record_after_update_callbacks
    model.run_record_after_update_callbacks(self)
  end
  
  before_destroy :run_record_before_destroy_callbacks
  def run_record_before_destroy_callbacks
    model.run_record_before_destroy_callbacks(self)
  end

  after_destroy :run_record_after_destroy_callbacks
  def run_record_after_destroy_callbacks
    model.run_record_after_destroy_callbacks(self)
  end
  
  
  
  # ----------------------------------------
  # Hierarchical methods
  # ----------------------------------------
  # insertion and deletion to maintin the integrity of the 'index' field
  before_validation :append_to_siblings
  before_destroy    :remove_from_siblings
  before_destroy    :destroy_children
  
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
  
  def destroy_children
    children.each(&:destroy)
  end
      
  # Siblings of this record (other records with the same parent)
  def siblings
    unless parent.nil?
      model.unscoped.where(:parent => parent.try(:id), :_id.ne => id).order('index asc')
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
  # Rendering
  # ----------------------------------------
  def content
    @content
  end
  
  def set_content(content)
    @content = content
  end
  
  def get_binding
    binding
  end
  
  
  # ----------------------------------------
  # Search
  # ----------------------------------------
  before_save :update_search_keywords
  def update_search_keywords
    return unless model.searchable?
    self.search_keywords = search_terms
  end
end
