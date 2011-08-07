module EmbeddedAssociation
  include AbstractModel
  
  def fields_field
    @fields_field ||= FieldsField.new(name)
  end
  
  def fields
    @fields ||= fields_field.typecast(@options['fields'], nil)
  end
  
  def options
    @options.merge({'fields' => fields_field.untypecast(fields, nil)})
  end
  
  def validate(record, errors)
    EmbeddedRecordsValidation.validate(self, record.get(name), record, errors)
    super(record, errors)
  end
  
  def default_input_type
    :embedded
  end
  
  private
    def process_json_item(embedded_record, store, record)
      return unless embedded_record.respond_to?(:to_hash)
      EmbeddedRecord.new(self, record, {}).tap {|new_record| new_record.from_json(embedded_record)}
    end
    
    def clear(store, record)
      if store.is_a?(Array)
        store.clear
      else
        record.set_raw(name, {})
        return {}
      end
    end
  
    def all(store, record)
      return [] if store.blank?
      store = [store] unless store.respond_to?(:collect)
      store.collect do |values|
        EmbeddedRecord.new(self, record, values)
      end
    end
end
