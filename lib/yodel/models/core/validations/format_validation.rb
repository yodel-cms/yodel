module Yodel
  class FormatValidation < Validation
    def self.validate(field, value, record, errors)
      return if field.format.nil?
      errors[field] << self unless value =~ Regexp.new(field.format)
    end
  
    def self.describe(field)
      "#{field.name.humanize} is not in the required format"
    end
  end
end
