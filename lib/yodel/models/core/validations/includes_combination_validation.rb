module Yodel
  class IncludesCombinationValidation < Validation
    def self.validate(field, value, record, errors)
      combinations = field.includes_combination
      return if combinations.blank?
      
      combinations.each do |included_combination|
        return if included_combination.all? {|required| value.include?(required)}
      end
      
      errors[field] << self
    end
  
    def self.describe(field)
      combinations = field.includes_combination.collect(&:to_s).join(', ')
      "#{field.name.humanize} must contain one of these combinations: #{combinations}"
    end
  end
end
