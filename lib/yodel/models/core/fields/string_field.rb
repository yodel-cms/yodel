module Yodel
  class StringField < Field
    def search_terms_set(str)
      str.to_s.gsub(/\W+/, ' ').split
    end
    
    def untypecast(value, record)
      value.nil? ? nil : value.to_s
    end
    
    def from_json(value, record)
      value.to_s
    end
  end
end
