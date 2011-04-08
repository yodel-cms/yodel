module Yodel
  class Validation
    @validations = []
  
    def self.validate(field, value, record, errors)
      @validations.each {|validation| validation.validate(field, value, record, errors)}
    end
  
    def self.describe(field)
      "#{field.name.humanize} is invalid"
    end
  
    def self.inherited(validation)
      @validations << validation
    end
  end
end
