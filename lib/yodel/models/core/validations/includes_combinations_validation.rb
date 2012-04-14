class IncludesCombinationsValidation < Validation
  validate do
    combinations = params['combinations']
    combinations.each do |included_combination|
      return if included_combination.all? {|required| value.include?(required)}
    end
    invalidate_with("must contain one of these combinations: #{combinations.map(&:to_s).join(', ')}")
  end
end
