module Yodel
  module StoreAssociation
    include Yodel::RecordAssociation
    
    def associate(associated_record, store, record)
      if store.is_a?(Array)
        store << associated_record.id
      else
        record.set_raw(name, associated_record.id)
      end
    end
    
    def validate(record, errors)
      # noop
    end
    
    def unassociate(associated_record, store, record)
      if store.is_a?(Array)
        store.delete(associated_record.id)
      else
        record.set_raw(name, nil)
      end
    end
    
    
    private
      def clear(store, record)
        if store.is_a?(Array)
          store.clear
        else
          record.set_raw(name, nil)
          return nil
        end
      end
      
      def all(store, record)
        query = record.site.model(model_name).where(_id: store)
        query = query.sort(@options['sort']) if @options['sort']
        query.all
      end
      
      def associated(store, record)
        return nil if store.nil?
        record.site.model(model_name).first(_id: store)
      end
  end
end
