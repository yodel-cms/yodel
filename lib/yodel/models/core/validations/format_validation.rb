module Yodel
  class FormatValidation < Validation
    def self.validate(params, field, name, value, record, errors)
      format = params['format']
      errors[field] << new(format, name) unless value =~ Regexp.new(format)
    end
  
    def describe
      "#{field} is not in the required format"
    end
  end
end
