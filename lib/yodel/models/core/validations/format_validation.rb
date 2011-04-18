module Yodel
  class FormatValidation < Validation
    def self.validate(params, field, name, value, record, errors)
      format = params['format']
      errors[field.name] << new(format) unless value =~ Regexp.new(format)
    end
  
    def describe
      "is not in the required format"
    end
  end
end
