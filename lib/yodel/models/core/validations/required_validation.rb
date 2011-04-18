module Yodel
  class RequiredValidation < Validation
    def self.validate(params, field, name, value, record, errors)
      errors[field.name] << new(params) if (value.blank? && !value.is_a?(FalseClass))
    end
  
    def describe
      "is required"
    end
  end
end
