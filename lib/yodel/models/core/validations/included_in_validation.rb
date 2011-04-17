module Yodel
  class IncludedInValidation < Validation
    def self.validate(params, field, name, value, record, errors)
      valid_values = params['valid_values']
      errors[field] << new(valid_values, name) unless valid_values.include?(value)
    end
  
    def describe
      "#{field} must be one of: #{params.join(', ')}"
    end
  end
end
