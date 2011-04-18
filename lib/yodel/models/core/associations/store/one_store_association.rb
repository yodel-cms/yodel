module Yodel
  class OneStoreAssociation < Association
    include Yodel::StoreAssociation
    include Yodel::OneAssociation
    
    def default_input_type
      :store_one
    end
    
    def untypecast(value, record)
      value.respond_to?(:id) ? value.id : nil
    end
    
    def record_options(record)
      query = model(record).where()
      query = query.sort(@options['order'].to_s) if @options['order']
      p query
      query.all.collect {|record| [record.name, record.id.to_s]}
    end
  end
end
