module Yodel
  class IncludesCombinationsValidation < Validation
    def self.validate(params, field, name, value, record, errors)
      combinations = params['combinations']
      combinations.each do |included_combination|
        return if included_combination.all? {|required| value.include?(required)}
      end
      errors[field.name] << new(combinations)
    end
  
    def describe
      combinations = params.collect(&:to_s).join(', ')
      "must contain one of these combinations: #{combinations}"
    end
  end
end
