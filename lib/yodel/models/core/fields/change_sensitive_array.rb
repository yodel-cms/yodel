module Yodel
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
    
    def push(value)
      notify!
      @array.push(value)
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
    
    def method_missing(name, *args, &block)
      @array.send(name, *args, &block)
    end
    
    private
      def notify!
        @record.try(:changed!, @field)
      end
  end
end
