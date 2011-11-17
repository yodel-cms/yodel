module RecordAssociation
  private
    def process_json_item(raw_id, store, record)
      return nil if raw_id.blank?
      associated_record = model(record).find(BSON::ObjectId.from_string(raw_id))
      if !associated_record.nil?
        if model_name == 'Model'
          return associated_record if associated_record.is_a?(Model)
        elsif associated_record.model.ancestors.include?(model(record))
          return associated_record
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
      # caching was causing a bug where running migrations on a new site would fail because
      # calls to NewModel.parent were generating the query:
      # {id: parent_id, _site_id: yodel_dev_site_id NOT new_site.id}
      #@model ||=
      case model_name
        when 'Site'
          Site
        when 'Remote'
          Remote
        else
          record.site.model(model_name)
        end
    end
end
