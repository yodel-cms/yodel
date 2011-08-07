module RecordAssociation
  private
    def process_json_item(raw_id, store, record)
      associated_record = model(record).find(BSON::ObjectId.from_string(raw_id))
      if !associated_record.nil? && associated_record.model.ancestors.include?(model(record))
        associated_record
      else
        nil
      end
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
