module Yodel
  module RecordAssociation
    private
      def process_json_item(raw_id, store, record)
        associated_record = model.find(BSON::ObjectId.from_string(raw_id))
        (associated_record.model_name == model_name) ? associated_record : nil
      end
      
      def foreign_key(record)
        @foreign_key ||= (options['foreign_key'] || record.try(:model_name).to_s.underscore)
        @foreign_key or raise "Records with no model name must specify a foreign_key on query associations"
      end
      
      def model_name
        @model_name ||= (options['model'] || name).to_s.classify
      end
      
      def model(record)
        @model ||= record.site.model(model_name)
      end
  end
end
