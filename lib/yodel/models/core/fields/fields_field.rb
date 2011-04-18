module Yodel
  class FieldsField < Field
    def typecast(hash, record)
      Yodel::ChangeSensitiveHash.new(record, name, fields_from_hash(hash, record))
    end
    
    def untypecast(hash, record)
      return {} unless hash.respond_to?(:to_hash)
      hash.to_hash.each_with_object({}) do |(name, field_obj), fields|
        next unless field_obj.is_a?(Field)
        fields[name.to_s] = field_obj.options
      end
    end
    
    def from_json(hash, record)
      # return {} unless hash.is_a?(Hash)
      #       hash.each_with_object({}) do |(name, options), fields|
      #         fields[name.to_s] = Field.from_options(name, options).options
      #       end
      fields_from_hash(hash, record)
    end
    
    private
      def fields_from_hash(hash, record)
        return {} unless hash.is_a?(Hash)
        hash.each_with_object({}) do |(name, options), fields|
          fields[name.to_s] = Field.from_options(name, options)
        end
      end
  end
end
