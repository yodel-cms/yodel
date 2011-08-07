class PasswordConfirmationValidation < Validation
  def self.validate(params, field, name, value, record, errors)
    #p record.field_was(field.name)
    return if record.field_was(field.name).nil?
    match = record.respond_to?(:passwords_match?) && record.passwords_match?(record.stash["current_#{name}"])
    errors[field.name] << new(name) unless match
  end

  def describe
    "didn't match your existing #{params}"
  end
end
