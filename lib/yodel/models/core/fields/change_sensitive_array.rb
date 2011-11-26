# Notify the record owning this value whenever the underlying array
# changes. Records rely on assignment to determine when a value has
# changed, so mutable objects need to notify the record when they are
# updated. This is not an exhaustive list of ways to mutate an array,
# just some common methods used in Yodel already.
class ChangeSensitiveArray
  attr_reader :array
  def initialize(record, field, array)
    @record = record
    @field = field
    @array = array
  end
  
  def inspect
    @array.inspect
  end
  
  def to_a
    @array
  end
  
  def to_s
    @array.collect(&:to_s).join(', ')
  end
  
  def push(value)
    notify!
    @array.push(value)
  end
  
  def clear
    notify!
    @array.clear
  end
  
  def pop
    notify!
    @array.pop
  end
  
  def <<(value)
    notify!
    @array << value
  end
  
  def delete(value)
    notify!
    @array.delete(value)
  end
  
  def []=(index, value)
    notify!
    @array[index] = value
  end
  
  def each(&block)
    @array.each(&block)
  end
  
  def collect(&block)
    @array.collect(&block)
  end
  
  def count(*item, &block)
    @array.count(*item, &block)
  end
  
  def size
    @array.size
  end
  
  def include?(item)
    @array.include?(item)
  end
  
  def method_missing(name, *args, &block)
    notify! if name.to_s.end_with?('!')
    @array.send(name, *args, &block)
  end
  
  # Calling changed! on @record will call dup on this array before any mutating
  # operation has been performed. We need to store the original unedited version
  # in typecast (the 'was' value), then return this array since the mutating
  # operation is being performed on it. Since dup returns self, the array being
  # operated on will be stored in @record.changed, and be modified by the op.
  def dup
    copy = ChangeSensitiveArray.new(@record.dup, @field.dup, @array.dup)
    @record.typecast[@field] = copy
    self
  end
  
  private
    def notify!
      @record.try(:changed!, @field)
    end
end
