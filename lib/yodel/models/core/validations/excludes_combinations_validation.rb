module Yodel
  class ExcludesCombinationsValidation < Validation
    def self.validate(params, field, name, value, record, errors)
      combinations = params['combinations']
      combinations.each do |excluded_combination|
        fail = excluded_combination.all? {|prohibited| value.include?(prohibited)}
        (errors[field] << new(combinations, name)) and return if fail
      end
    end
  
    def describe
      combinations = params.collect(&:to_s).join(', ')
      "#{field} cannot contain these combinations: #{combinations}"
    end
  end
end
