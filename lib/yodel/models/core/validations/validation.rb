class Validation
  # validation subclasses define blocks which are added to the ValidationErrors
  # class as methods to be run when performing a particular validation. The
  # 'validation_' prefix is used to keep validation methods from clashing with
  # built in methods e.g 'length' vs 'validate_length'.
  def self.validate(&block)
    ValidationErrors.send(:define_method, "validate_#{self.name.sub('Validation', '').underscore}", block)
  end
end
