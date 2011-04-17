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
      end
      validation.validate(params, field, name, value, record, errors)
    end
    
    def initialize(params, field)
      @params = params
      @field = field
    end
  
    def describe
      "#{field} is invalid"
    end
  end
end
