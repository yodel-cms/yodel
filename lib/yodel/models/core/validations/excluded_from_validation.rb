module Yodel
  class ExcludedFromValidation < Validation
    def self.validate(field, value, record, errors)
      prohibited_values = field.excluded_from
      return if prohibited_values.blank?
      errors[field] << self if prohibited_values.include?(value)
    end
  
    def self.describe(field)
      "#{field.name.humanize} must not be: #{field.excluded_from.join(', ')}"
    end
  end
end
