module Yodel
  class UniqueValidation < Validation
    def self.validate(field, value, record, errors)
      return unless field.unique?
      errors[field] << self if record.model.exists?(field.name => value, :_id.ne => record.id)
    end
  
    def self.describe(field)
      "#{field.name.humanize} must be unique"
    end
  end
end
