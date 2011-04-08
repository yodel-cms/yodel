module Yodel
  class StringField < Field
    def search_terms_set(str)
      str.gsub(/\W+/, ' ').split
    end
    
    def from_json(value, record)
      record.set_raw(name, value.to_s)
    end
  end
end
