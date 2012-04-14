class FormatValidation < Validation
  validate do
    invalidate_with("is not in the required format") unless value =~ Regexp.new(params['format'])
  end
end
