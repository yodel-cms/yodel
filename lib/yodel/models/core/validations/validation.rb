class Validation
  attr_accessor :params, :field
  
  def self.validate(type, params, field, name, value, record, errors)
    validation = case type
    when 'excluded_from'
      ExcludedFromValidation
    when 'excludes_combinations'
      ExcludesCombinationsValidation
    when 'format'
      FormatValidation
    when 'included_in'
      IncludedInValidation
    when 'includes_combinations'
      IncludesCombinationsValidation
    when 'length'
      LengthValidation
    when 'required'
      RequiredValidation
    when 'unique'
      UniqueValidation
    when 'password_confirmation'
      PasswordConfirmationValidation
    end
    validation.validate(params, field, name, value, record, errors)
  end
  
  def initialize(params)
    @params = params
  end

  def describe
    "is invalid"
  end
  
  def to_json(*a)
    describe.to_json(*a)
  end
end
