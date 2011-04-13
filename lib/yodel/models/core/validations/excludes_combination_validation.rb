module Yodel
  class ExcludesCombinationValidation < Validation
    def self.validate(field, value, record, errors)
      combinations = field.excludes_combination
      return if combinations.blank?
      
      combinations.each do |excluded_combination|
        fail = excluded_combination.all? {|prohibited| value.include?(prohibited)}
        (errors[field] << self) and return if fail
      end
    end
  
    def self.describe(field)
      combinations = field.excludes_combination.collect(&:to_s).join(', ')
      "#{field.name.humanize} cannot contain these combinations: #{combinations}"
    end
  end
end
