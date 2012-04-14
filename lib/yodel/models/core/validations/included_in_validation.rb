class IncludedInValidation < Validation
  validate do
    allowed_values = params['valid_values']
    invalidate_with("must be one of: #{allowed_values.join(', ')}") unless allowed_values.include?(value)
  end
end
