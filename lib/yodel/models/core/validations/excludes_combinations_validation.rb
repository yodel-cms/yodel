module Yodel
  class ExcludesCombinationsValidation < Validation
    def self.validate(params, field, name, value, record, errors)
      combinations = params['combinations']
      combinations.each do |excluded_combination|
        fail = excluded_combination.all? {|prohibited| value.include?(prohibited)}
        (errors[field.name] << new(combinations)) and return if fail
      end
    end
  
    def describe
      combinations = params.collect.with_index {|combo, index| "#{index + 1}. #{combo.to_sentence}"}
      "may not be in these combinations: #{combinations.to_sentence(two_words_connector: ', and ')}"
    end
  end
end
