class ExcludedFromValidation < Validation
  def self.validate(params, field, name, value, record, errors)
    prohibited_values = params['prohibited_values']
    errors[field.name] << new(prohibited_values) if prohibited_values.include?(value)
  end

  def describe
    "must not be: #{params.join(', ')}"
  end
end
