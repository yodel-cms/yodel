class ChangeSensitiveHash
  attr_reader :hash
  def initialize(record, field, hash)
    @record = record
    @field = field
    @hash = hash
  end
  
  def inspect
    @hash.inspect
  end
  
  def to_hash
    @hash
  end
  
  def merge!(other_hash)
    notify!
    @hash.merge!(other_hash)
  end
  
  def delete(key)
    notify!
    @hash.delete(key)
  end
  
  def clear
    notify!
    @hash.clear
  end
  
  def []=(key, value)
    notify!
    @hash[key] = value
  end
  
  def method_missing(name, *args, &block)
    notify! if name.to_s.end_with?('!')
    @hash.send(name, *args, &block)
  end
  
  # See ChangeSensitiveArray#dup for an explanation of this method
  def dup
    copy = ChangeSensitiveHash.new(@record.dup, @field.dup, @hash.dup)
    @record.typecast[@field] = copy
    self
  end
  
  private
    def notify!
      @record.try(:changed!, @field)
    end
end
