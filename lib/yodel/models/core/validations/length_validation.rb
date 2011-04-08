module Yodel
  class LengthValidation < Validation
    def self.validate(field, value, record, errors)
      return if field.length.blank?
      min, max = field.length
    
      if min == 0
        valid = (value.size <= max)
      elsif max == 0
        valid = (value.size >= min)
      else
        valid = (value.size >= min) && (value.size <= max)
      end
    
      errors[field] << self unless valid
    end
  
    def self.describe(field)
      min, max = field.length

      if min == 0
        "#{field.name.humanize} is too long (maximum length is #{max} characters)"
      elsif max == 0
        "#{field.name.humanize} is too short (minimum length is #{min} characters)"
      else
        "#{field.name.humanize} must be between #{min} and #{max} characters"
      end
    end
  end
end
