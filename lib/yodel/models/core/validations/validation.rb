module Yodel
  class Validation
    attr_accessor :params, :field
    
    def self.validate(type, params, field, name, value, record, errors)
      validation = case type
      when 'excluded_from'
        Yodel::ExcludedFromValidation
      when 'excludes_combinations'
        Yodel::ExcludesCombinationsValidation
      when 'format'
        Yodel::FormatValidation
      when 'included_in'
        Yodel::IncludedInValidation
      when 'includes_combinations'
        Yodel::IncludesCombinationsValidation
      when 'length'
        Yodel::LengthValidation
      when 'required'
        Yodel::RequiredValidation
      when 'unique'
        Yodel::UniqueValidation
      when 'password_confirmation'
        Yodel::PasswordConfirmationValidation
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
end
