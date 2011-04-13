module Yodel
  module ManyAssociation
    def before_destroy(record)
      if @options['destroy'] == true
        record.get(name).each(&:destroy)
      end
    end
    
    def typecast(value, record)
      return Yodel::ChangeSensitiveArray.new(record, name, []) if value.blank?
      raise "ManyAssociation values must be enumerable (#{name})" unless value.respond_to?(:each)
      Yodel::ChangeSensitiveArray.new(record, name, all(value, record))
    end
    
    def untypecast(value, record)
      return nil if value.blank?
      raise "ManyAssociation values must be enumerable (#{name})" unless value.respond_to?(:each)
      
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
  end
end
