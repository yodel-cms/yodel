module Yodel
  class RequiredValidation < Validation
    def self.validate(field, value, record, errors)
      return unless field.required?
      errors[field] << self if value.blank?
    end
  
    def self.describe(field)
      "#{field.name.humanize} is required"
    end
  end
end
