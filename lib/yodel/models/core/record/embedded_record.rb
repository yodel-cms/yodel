require './record/abstract_record'

class EmbeddedRecord < AbstractRecord
  attr_reader :embedded_field, :parent_record
  
  def initialize(embedded_field, parent_record, values={})
    @embedded_field = embedded_field
    @parent_record = parent_record
    super(values)
  end
  
  def site
    parent_record.site
  end
  
  def set(name, value)
    super
    parent_record.changed!(embedded_field.name)
  end
  
  def set_raw(name, value)
    super
    parent_record.changed!(embedded_field.name)
  end
      
  def changed!(name)
    super
    parent_record.changed!(embedded_field.name)
  end
  
  def fields
    embedded_field.fields
  end
  
  def perform_save
    embedded_field.save(self, parent_record)
  end

  def perform_destroy
    embedded_field.destroy(self, parent_record)
  end
  
  def perform_reload(id)
    # TODO: determine whether reloading the parent record will cause any problems
    self
  end
end
