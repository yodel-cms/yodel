module Yodel
  module AbstractModel
    def fields
      @fields ||= {}
    end
    
    def field(name, type, options={})
      type = type.to_s
      options.stringify_keys!
      fields[name.to_s] = Yodel::Field.field_from_type(type).new(name.to_s, {'type' => type}.merge(options))
    end
    alias :add_field :field
    
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
      type = (options[:store] == false) ? 'many_query' : 'many_store'
      field(name, type, options)
    end
    alias :add_many :many
    
    def one(name, options={})
      type = (options[:store] == false) ? 'one_query' : 'one_store'
      field(name, type, options)
    end
    alias :add_one :one
  end
end
