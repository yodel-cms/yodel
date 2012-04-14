class PasswordConfirmationValidation < Validation
  validate do
    return if record.field_was(field.name).nil? || record.stash["current_#{field.name}"].nil? || !record.respond_to?(:passwords_match?)
    match = record.passwords_match?(record.stash["current_#{field.name}"])
    invalidate_with("didn't match your existing #{field.name.humanize.downcase}") unless match
  end
end
