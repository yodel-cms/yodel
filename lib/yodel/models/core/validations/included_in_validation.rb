module Yodel
  class IncludedInValidation < Validation
    def self.validate(field, value, record, errors)
      valid_values = field.included_in
      return if valid_values.blank?
      errors[field] << self unless valid_values.include?(value)
    end
  
    def self.describe(field)
      "#{field.name.humanize} must be one of: #{field.included_in.join(', ')}"
    end
  end
end
