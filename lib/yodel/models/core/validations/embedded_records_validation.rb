class EmbeddedRecordsValidation < Validation
  def initialize(params, errors)
    super(params)
    @errors = errors
  end
  
  def self.validate(field, records, record, errors)
    # embedded record validations
    records = [records] unless records.respond_to?(:to_a)
    embedded_errors = Errors.new
    records.to_a.each_with_index do |embedded_record, index|
      embedded_errors[index] = embedded_record.valid? ? nil : embedded_record.errors
    end
    
    # field set validations
    field.fields.each do |name, embedded_field|
      next unless embedded_field.set_validations
      set_value = records.to_a.collect {|embedded| embedded.get(name)}.uniq
      embedded_field.set_validations.each do |type, params|
        Validation.validate(type, params, embedded_field, name, set_value, record, embedded_errors)
      end
    end
    
    errors[field.name] = embedded_errors unless embedded_errors.empty?
  end

  def describe
    # FIXME: don't just call inspect here, format correctly using describe calls
    "has these errors: #{@errors.inspect}}"
  end
end
