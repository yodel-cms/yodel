class ExcludesCombinationsValidation < Validation
  validate do
    combinations = params['combinations']
    combinations.each do |excluded_combination|
      if excluded_combination.all? {|prohibited| value.include?(prohibited)}
        if combinations.size > 1
          combinations_list = combinations.collect.with_index {|combo, index| "#{index + 1}. #{combo.to_sentence}"}
        else
          combinations_list = [combinations.first.to_sentence]
        end
        invalidate_with("may not contain #{combinations_list.size == 1 ? 'this' : 'these'} combination#{'s' if combinations_list.size > 1}: #{combinations_list.to_sentence(two_words_connector: ', and ')}")
        return
      end
    end
  end
end
