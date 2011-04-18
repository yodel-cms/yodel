module Yodel
  class EmbeddedRecordsValidation < Validation
    def initialize(params, errors)
      super(params)
      @errors = errors
    end
    
    def self.validate(field, records, record, errors)
      records = [records] unless records.respond_to?(:to_a)
      record_errors = records.to_a.collect {|embedded| embedded.valid? ? nil : embedded.errors}
      errors[field.name] << new(nil, record_errors) unless record_errors.compact.empty?
      
      field.fields.each do |name, field|
        next unless field.set_validations
        set_value = records.to_a.collect {|embedded| embedded.get(name)}.uniq
        set_name = name.pluralize.humanize
        field.set_validations.each do |type, params|
          Yodel::Validation.validate(type, params, field, set_name, set_value, record, errors)
        end
      end
    end
  
    def describe
      # FIXME: don't just call inspect here, format correctly using describe calls
      "has these errors: #{@errors.inspect}}"
    end
  end
end
