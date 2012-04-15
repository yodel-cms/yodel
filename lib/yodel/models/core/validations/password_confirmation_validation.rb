class PasswordConfirmationValidation < Validation
  validate do
    return if record.field_was(field.name).nil? || !record.changed?(field.name) || !record.respond_to?(:passwords_match?)
    unless record.passwords_match?(record.stash["current_#{field.name}"])
      invalidate_with("didn't match your existing #{field.name.humanize.downcase}")
    end
  end
end
