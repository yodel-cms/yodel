module Yodel
  class RequiredValidation < Validation
    def self.validate(params, field, name, value, record, errors)
      errors[field] << new(params, name) if (value.blank? && !value.is_a?(FalseClass))
    end
  
    def describe
      "#{field} is required"
    end
  end
end
