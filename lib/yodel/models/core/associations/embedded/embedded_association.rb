module Yodel
  module EmbeddedAssociation
    include Yodel::AbstractModel
    
    def fields_field
      @fields_field ||= Yodel::FieldsField.new(name)
    end
    
    def fields
      @fields ||= fields_field.typecast(@options['fields'], nil)
    end
    
    def options
      @options.merge({'fields' => fields_field.untypecast(fields, nil)})
    end
    
    def validate(record, errors)
      Yodel::EmbeddedRecordsValidation.validate(self, record.get(name), record, errors)
      super
    end
    
    
    private
      def process_json_item(embedded_record, store, record)
        #associated_record = model.find(BSON::ObjectId.from_string(raw_id))
        #(associated_record.model_name == model_name) ? associated_record : nil
        embedded_record
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
          Yodel::EmbeddedRecord.new(self, record, values)
        end
      end
  end
end
