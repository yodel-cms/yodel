class ExcludedFromValidation < Validation
  validate do
    prohibited_values = params['prohibited_values']
    invalidate_with("must not be: #{prohibited_values.join(', ')}") if prohibited_values.include?(value)
  end
end
