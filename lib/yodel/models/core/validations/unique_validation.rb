module Yodel
  class UniqueValidation < Validation
    def self.validate(params, field, name, value, record, errors)
      errors[field] << new(params, name) if record.model.exists?(field.name => value, :_id.ne => record.id)
    end
  
    def describe
      "#{field} must be unique"
    end
  end
end
