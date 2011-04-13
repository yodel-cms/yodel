module Yodel
  class HashField < Field
    # TODO: validate should defer to @element_type over each element
    def initialize(name, options={})
      @element_type = Field.from_options(name, 'type' => options['of'].to_s) if options['of']
      super
    end
    
    def json_action(action, value, record)
      hash = record.get_raw(name)
      
      if action == 'remove'
        value = [value] unless value.is_a?(Array)
        keys = value.collect(&:to_s)
        hash.delete_if {|key, _| keys.include?(key)}
      else
        raise "Set or merge actions on a hash must be passed a hash" unless value.is_a?(Hash)
        value = process(value, record, :from_json)
        if action == 'set'
          hash = value
        elsif action == 'merge'
          hash.merge!(value)
        end
      end
      
      record.set_raw(name, hash)
    end
  
    def typecast(value, record)
      value = {} unless value.is_a?(Hash)
      Yodel::ChangeSensitiveHash.new(record, name, process(value, record, :typecast))
    end
    
    def untypecast(value, record)
      return {} if value.blank? || !value.respond_to?(:to_hash)
      process(value, record, :untypecast)
    end
    
    def from_json(value, record)
      return {} if value.blank? || !value.is_a?(Hash)
      process(value, record, :from_json)
    end
    
    
    private
      def process(hash, record, method)
        return hash if @element_type.nil?
        hash.to_hash.each do |key, value|
          hash[key.to_s] = @element_type.send(method, value, record)
        end
      end
  end
end
