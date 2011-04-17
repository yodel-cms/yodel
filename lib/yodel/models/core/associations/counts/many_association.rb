module Yodel
  module ManyAssociation
    def search_terms_set(record)
      return [] unless include_in_search_keywords?
      record.get(name).collect do |embedded_record|
        embedded_record.search_terms
      end.flatten
    end
    
    def before_destroy(record)
      if @options['destroy'] == true
        record.get(name).each(&:destroy)
      end
    end
    
    def typecast(value, record)
      Yodel::ChangeSensitiveArray.new(record, name, all(value, record))
    end
  end
end
