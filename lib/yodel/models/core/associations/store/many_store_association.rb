module Yodel
  class ManyStoreAssociation < Association
    include Yodel::StoreAssociation
    include Yodel::ManyAssociation
    
    def typecast(value, record)
      return Yodel::ChangeSensitiveArray.new(record, name, []) if value.blank?
      raise "ManyStoreAssociation values must be enumerable (#{name})" unless value.respond_to?(:each)
      Yodel::ChangeSensitiveArray.new(record, name, all(value, record))
    end
    
    def untypecast(value, record)
      return nil if value.blank?
      raise "ManyStoreAssociation values must be enumerable (#{name})" unless value.respond_to?(:each)
      
      store = record.get_raw(name) || []
      store.clear
      value.each do |associated_record|
        store << associated_record.id
      end
      store
    end
    
    def default
      @options['default'] || []
    end
  end
end
