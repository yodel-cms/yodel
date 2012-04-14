class RequiredValidation < Validation
  validate do
    invalidate_with("is_required") if value.blank? && !value.is_a?(FalseClass)
  end
end
