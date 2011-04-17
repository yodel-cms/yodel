module Yodel
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
    
    def []=(key, value)
      notify!
      @hash[key] = value
    end
    
    def method_missing(name, *args, &block)
      @hash.send(name, *args, &block)
    end
    
    private
      def notify!
        @record.try(:changed!, @field)
      end
  end
end
