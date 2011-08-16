module RecordAssociation
  private
    def process_json_item(raw_id, store, record)
      return nil if raw_id.blank?
      associated_record = model(record).find(BSON::ObjectId.from_string(raw_id))
      if !associated_record.nil?
        if model_name == 'Model'
          return associated_record if associated_record.is_a?(Model)
        elsif associated_record.model.ancestors.include?(model(record))
          associated_record
        end
      end
      nil
    end
    
    def foreign_key(record)
      @foreign_key ||= (options['foreign_key'] || model_name.to_s.underscore) # FIXME: should be foreign_key || record.model.name.underscore
    end
    
    def model_name
      @model_name ||= (options['model'] || name).to_s.classify
    end
    
    def model(record)
      @model ||= record.site.model(model_name)
    end
end
