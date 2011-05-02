module Yodel
  module AbstractModel
    def fields
      @fields ||= {}
    end
    
    def field(name, type, options={})
      type = type.to_s
      options = deep_stringify_keys({'type' => type}.merge(options))
      fields[name.to_s] = Yodel::Field.field_from_type(type).new(name.to_s, options)
    end
    alias :add_field :field
    
    def modify_field(name, options={})
      fields[name.to_s].options.merge!(options)
    end
    
    def embed_many(name, options={}, &block)
      embedded_field = field(name, 'many_embedded', options)
      embedded_field.instance_exec(embedded_field, &block) if block_given?
    end
    alias :add_embed_many :embed_many
    
    def embed_one(name, options={}, &block)
      embedded_field = field(name, 'one_embedded', options)
      embedded_field.instance_exec(embedded_field, &block) if block_given?
    end
    alias :add_embed_one :embed_one
    
    def many(name, options={})
      type = query_association?(options) ? 'many_query' : 'many_store'
      field(name, type, options)
    end
    alias :add_many :many
    
    def one(name, options={})
      type = query_association?(options) ? 'one_query' : 'one_store'
      field(name, type, options)
    end
    alias :add_one :one
    
    
    protected
      def query_association?(options)
        options[:store] == false || [:foreign_key, :extends, :through].any? {|opt| options[opt].present?}
      end
      
      def deep_stringify_keys(hash)
        hash.each_with_object({}) do |(key, value), new_hash|
          new_hash[key.to_s] = (value.respond_to?(:to_hash) ? deep_stringify_keys(value) : value)
        end
      end
  end
end
