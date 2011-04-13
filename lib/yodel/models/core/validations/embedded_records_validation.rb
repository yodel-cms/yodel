module Yodel
  # Doesn't inherit from Validation so it's not included in normal validations
  class EmbeddedRecordsValidation
    def initialize(errors)
      @errors = errors
    end
    
    def self.validate(field, records, record, errors)
      records = [records] unless records.respond_to?(:to_a)
      record_errors = records.to_a.collect {|embedded| embedded.valid? ? nil : embedded.errors}
      errors[field] << new(record_errors) unless record_errors.compact.empty?
    end
  
    def describe(field)
      # FIXME: don't just call inspect here, format correctly using describe calls
      "#{field.name.humanize} has these errors: #{@errors.inspect}}"
    end
  end
end
