module Yodel
  class ExcludedFromValidation < Validation
    def self.validate(params, field, name, value, record, errors)
      prohibited_values = params['prohibited_values']
      errors[field] << new(prohibited_values, name) if prohibited_values.include?(value)
    end
  
    def describe
      "#{field} must not be: #{params.join(', ')}"
    end
  end
end
