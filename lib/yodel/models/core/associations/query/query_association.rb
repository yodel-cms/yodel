module Yodel
  module QueryAssociation
    include Yodel::RecordAssociation
    
    def strip_nil?
      true
    end
    
    def associate(associated_record, store, record)
      associated_record.set_meta(foreign_key, record.id)
      associated_record.save_without_validation
    end
    
    def unassociate(associated_record, store, record)
      return unless associated_record.get_meta(foreign_key) == record.id
      associated_record.set_meta(foreign_key, nil)
      associated_record.save_without_validation
    end
    
    private
      def clear(store, record)
        all(store, record).each {|associated_record| unassociate(associated_record, store, record)}
      end
      
      def all(store, record)
        query = record.site.model(model_name).where(foreign_key => record.id)
        query = query.sort(@options['sort']) if @options['sort']
        query.all
      end
      
      def associated(store, record)
        record.site.model(model_name).first(foreign_key => record.id)
      end
  end
end
