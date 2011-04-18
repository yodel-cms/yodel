module Yodel
  class Errors
    def initialize
      @errors = {}
    end
    
    def inspect
      @errors.inspect
    end
    
    def [](name)
      @errors[name] ||= []
      @errors[name]
    end
    
    def key?(name)
      @errors.key?(name)
    end
    
    def empty?
      @errors.empty?
    end
    
    def to_json(*a)
      @errors.each_with_object({}) do |(field, errors), hash|
        hash[field.to_s] = "#{field.to_s.humanize} #{errors.collect(&:describe).to_sentence}"
      end.to_json(*a)
    end
  end
end
