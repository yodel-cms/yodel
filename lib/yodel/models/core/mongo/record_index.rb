require './record/mongo_record'
require './record/record'
require './model/mongo_model'

class RecordIndex < MongoRecord
  extend MongoModel
  collection :record_indexes
  field :spec, :array, of: :strings, required: true
  field :references, :array, of: :strings, required: true
  field :name, :string, required: true
  
  # ----------------------------------------
  # Index creation is handled by RecordIndex
  # ----------------------------------------
  def self.add_index(model_reference, spec)
    name = index_name(spec)
    index = self.scoped.where(name: name).first
    
    if index.nil?
      index = new
      index.spec = spec
      index.name = name
    end
    
    index.references << model_reference
    index.save
  end
  
  def self.remove_index(model_reference)
    index = self.scoped.where(references: model_reference).first
    return false if index.nil?
    index.references.delete(model_reference)
    
    if index.references.empty?
      index.destroy
    else
      index.save
    end
  end
  
  
  # ----------------------------------------
  # Helper methods
  # ----------------------------------------
  def self.add_index_for_field(model, field)
    name = model_index_name(model, field.name)
    spec = [[field.name, Mongo::ASCENDING]]
    add_index(name, spec)
  end
  
  def self.add_index_for_model(model, name, spec)
    name = model_index_name(model, name)
    add_index(name, spec)
  end
  
  def self.remove_index_for_field(model, field)
    name = model_index_name(model, field.name)
    remove_index(name)
  end
  
  def self.remove_index_for_model(model, name)
    name = model_index_name(model, name)
    remove_index(name)
  end
  
  
  # ----------------------------------------
  # Actual index construction/deletion
  # ----------------------------------------
  after_destroy :remove_index
  def remove_index
    Record.collection.drop_index(name)
  end
  
  before_create :create_index
  def create_index
    Record.collection.create_index(spec, name: name, background: true)
  end
  
  
  private
    def self.model_index_name(model, name)
      "#{model.site.id.to_s}_#{model.name}_#{name}"
    end
    
    def self.index_name(spec)
      spec.collect {|field| field.collect(&:to_s).join('_')}.join('_')
    end
end
