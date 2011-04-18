module Yodel
  class LengthValidation < Validation
    def self.validate(params, field, name, value, record, errors)
      length = params['length']
      min, max = length
    
      if min == 0
        valid = (value.size <= max)
      elsif max == 0
        valid = (value.size >= min)
      else
        valid = (value.size >= min) && (value.size <= max)
      end
    
      errors[field.name] << new(length) unless valid
    end
  
    def describe
      min, max = params

      if min == 0
        "is too long (maximum length is #{max} characters)"
      elsif max == 0
        "is too short (minimum length is #{min} characters)"
      else
        "must be between #{min} and #{max} characters"
      end
    end
  end
end
