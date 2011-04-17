module Yodel
  class ManyEmbeddedAssociation < Association
    include Yodel::EmbeddedAssociation
    include Yodel::ManyAssociation
    
    # remove ManyAssociation's destroy behaviour since embedded
    # records are destroyed as part of the parent anyway
    undef :before_destroy
    
    def search_terms_set(record)
      record.get(name).collect do |embedded_record|
        embedded_record.search_terms
      end.flatten
    end
    
    def options
      super.merge({'type' => 'many_embedded'})
    end
    
    def save(embedded_record, parent_record)
      if embedded_record.new?
        parent_record.get(name) << embedded_record
      end
    end
  
    def destroy(embedded_record, parent_record)
      parent_record.get(name).delete(embedded_record)
    end
    
    def associate(embedded_record, store, record)
      raise "Associated record must be an Embedded Record" unless embedded_record.is_a?(EmbeddedRecord)
      embedded_record.save
      store << embedded_record.values
    end
    
    def unassociate(embedded_record, store, record)
      store.delete(embedded_record)
    end
    
    def untypecast(value, record)
      return nil if value.blank?
      raise "ManyEmbeddedAssociation values must be enumerable (#{name})" unless value.respond_to?(:each)
      
      store = record.get_raw(name)
      clear(store, record)
      value.each do |associated_record|
        associate(associated_record, store, record)
      end
      store
    end
    
    def default
      @options['default'] || []
    end
    
    def typecast(value, record)
      return Yodel::EmbeddedRecordArray.new(record, self, []) if value.blank?
      raise "ManyEmbedded values must be enumerable (#{name})" unless value.respond_to?(:each)
      Yodel::EmbeddedRecordArray.new(record, self, all(value, record))
    end
  end
end
