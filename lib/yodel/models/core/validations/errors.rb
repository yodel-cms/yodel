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
  
  def []=(name, value)
    return if value.nil?
    @errors[name] = value
  end
  
  def key?(name)
    @errors.key?(name)
  end
  
  def empty?
    @errors.empty?
  end
  
  def clear
    @errors.clear
    @summary = nil
  end
  
  # errors on a collection
  def <<(error)
    self['_'] << error
  end
  
  def summarise
    @summary ||= @errors.each_with_object({}) do |(field, errors), hash|
      if errors.respond_to?(:summarise)
        hash[field.to_s] = errors.summarise.values.to_sentence
      else
        hash[field.to_s] = "#{field.to_s.humanize} #{errors.collect(&:describe).to_sentence}"
      end
    end
  end
  
  def to_json(*a)
    summarise.to_json(*a)
  end
end
