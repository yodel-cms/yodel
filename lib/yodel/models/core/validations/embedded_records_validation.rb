class EmbeddedRecordsValidation < Validation
  validate do
    # embedded record validations
    records = value.respond_to?(:to_a) ? value.to_a : [value]
    records.each do |embedded_record|
      add_embedded_errors(embedded_record) unless embedded_record.valid?
    end
    
    # field set validations - validations that apply over the set of values
    # of a field in a group of embedded records. e.g out of all values of
    # colour, red and green cannot both exist in a group of embedded recs.
    embedded_fields = []
    field_set_values = []
    
    field.fields.each do |field_name, embedded_field|
      next unless embedded_field.set_validations.present?
      embedded_fields << embedded_field
      field_set_values << Set.new(records.collect {|embedded| embedded.get(field_name)}).to_a
    end
    
    run_validations(embedded_fields, :set_validations, field_set_values, field)
  end
end
