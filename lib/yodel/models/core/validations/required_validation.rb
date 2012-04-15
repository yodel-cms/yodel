class RequiredValidation < Validation
  validate do
    invalidate_with("is required") if value.blank? && !value.is_a?(FalseClass)
  end
end
