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
      if params.size > 1
        combinations = params.collect.with_index {|combo, index| "#{index + 1}. #{combo.to_sentence}"}
      else
        combinations = [params.first.to_sentence]
      end
      "may not contain #{combinations.size == 1 ? 'this' : 'these'} combination#{'s' if combinations.size > 1}: #{combinations.to_sentence(two_words_connector: ', and ')}"
    end
  end
end
