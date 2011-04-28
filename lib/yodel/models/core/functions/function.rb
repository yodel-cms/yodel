module Yodel
  class Function
    attr_accessor :instructions, :source
    
    def initialize(param)
      if param.is_a?(String)
        @source = param
        @instructions = compile(param)
      else
        @instructions = param
      end
    end
    
    def inspect(instruction=nil)
      instruction ||= self.instructions
      
      name = instruction.shift
      parameters = instruction.collect do |parameter|
        if parameter.is_a?(Array)
          inspect(parameter)
        else
          parameter
        end
      end

      "#{name}(#{parameters.join(', ')})"
    end
    
    
    # ----------------------------------------
    # Compilation
    # ----------------------------------------
    CALL_TOKEN          = '.'
    START_PARAMS_TOKEN  = '('
    END_PARAMS_TOKEN    = ')'
    START_HASH_TOKEN    = '{'
    END_HASH_TOKEN      = '}'
    PARAM_DELIM_TOKEN   = ','
    HASH_DELIM_TOKEN    = ':'
    ENTRY_FLAG          = '!'
    DOUBLE_QUOTE_TOKEN  = '"'
    SINGLE_QUOTE_TOKEN  = "'"

    def compile(source)
      tokens = source.scan(/[\w\-\+]+|\.|\(|\)|\{|\}|:|,|"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'/)
      parse(tokens)
    end

    def parse(tokens)
      params = false
      chain  = false
      hash   = false
      instructions = []

      until tokens.empty?
        token = tokens.shift
        case token[0]
        when CALL_TOKEN
          chain = true
        when START_PARAMS_TOKEN
          params = true
          instructions += parse(tokens)
        when END_PARAMS_TOKEN
          tokens.unshift(END_PARAMS_TOKEN) unless params
          break
        when ENTRY_FLAG
          hash = true
          instructions << ['entry'] + parse(tokens)
        when START_HASH_TOKEN
          tokens.unshift(ENTRY_FLAG)
          instructions << ['hash'] + parse(tokens)
        when END_HASH_TOKEN
          tokens.unshift(END_HASH_TOKEN) if hash
          break
        when HASH_DELIM_TOKEN
          instructions += parse(tokens)
        when PARAM_DELIM_TOKEN
          if params || hash
            tokens.unshift(ENTRY_FLAG) if hash
            instructions += parse(tokens)
          else
            tokens.unshift(PARAM_DELIM_TOKEN)
            break
          end
        when DOUBLE_QUOTE_TOKEN, SINGLE_QUOTE_TOKEN
          instructions << ['string', token[1...-1]]
        else
          if tokens.first == START_PARAMS_TOKEN
            instructions << [token] + parse(tokens)
          elsif token.to_i.to_s == token
            instructions << ['int', token]
          else
            instructions << ['field', token]
          end
        end
      end

      if chain
        [['chain'] + instructions]
      else
        instructions
      end
    end
    
    # ----------------------------------------
    # Execution
    # ----------------------------------------
    def execute(context, instruction=nil, parent_context = nil)
      instruction ||= self.instructions.first
      name, *params = instruction

      case name
      when 'chain'
        chain(context, params)
      when 'field'
        get_field(context, params.first)
      when 'changed'
        changed(context, params.first)
      when 'collect'
        collect(context, params.first)
      when 'majority'
        majority(context, params.first)
      when 'count'
        count(context, params.first)
      when 'invert'
        invert(context)
      when 'unique'
        unique(context, params.first)
      when 'average'
        average(context, params)
      when 'present'
        present(context)
      when 'blank'
        blank(context)
      when 'sum'
        sum(context, params)
      when 'round'
        round(context)
      when 'if'
        binary_if(context, params[0], params[1], params[2])
      when 'strip'
        strip(context)
      when 'format'
        format(context, params.first)
      when 'set'
        parent_context ||= context
        set_field(context, parent_context, params[0], params[1])
      when 'update'
        parent_context ||= context
        update_field(context, parent_context, params[0], params[1])
      when 'min'
        min(context, params[0], params[1])
      when 'max'
        max(context, params[0], params[1])
      when 'increment'
        increment(context, params[0], params[1])
      when 'each'
        each(context, params.first)
      when 'deliver'
        deliver_email(context, params[0], params[1])
      when 'call_api'
        call_api(context, params[0], params[1])
        
      # literals
      when 'string'
        params.first
      when 'int'
        params.first.to_i
      when 'hash'
        Hash[params.collect {|entry| execute(context, entry)}]
      when 'entry'
        [execute(context, params.first), execute(context, params.last)]
      end
    end
    
    protected
      def chain(context, methods)
        parent_context = context
        methods.each do |method|
          context = execute(context, method, parent_context)
        end
        context
      end

      def get_field(context, name)
        name == 'self' ? context : context.get(name)
      end
      
      # TODO: change format from changed('name') to name.changed
      def changed(context, name)
        context.changed?(execute(context, name))
      end
      
      def set_field(context, parent_context, field, value)
        field = execute(parent_context, field)
        value = execute(parent_context, value)
        context.set(field, value)
      end
      
      def update_field(context, parent_context, field, value)
        set_field(context, parent_context, field, value)
        context.save
      end
      
      def increment(context, field, value)
        field = execute(context, field)
        value = execute(context, value)
        context.increment!(field, value)
      end

      def collect(context, field)
        raise "Context to collect must respond to collect" unless context.respond_to?(:collect)
        context.collect {|item| execute(item, field)}
      end
      
      def each(context, statement)
        raise "Context to each must respond to each" unless context.respond_to?(:each)
        context.each {|item| execute(item, statement)}
      end

      def majority(context, field)
        unless context.respond_to?(:size) && context.respond_to?(:count)
          raise "Majority context must be enumerable"
        end

        valid = context.count {|item| execute(item, field)}
        valid >= (context.size - valid)
      end
      
      def count(context, field)
        unless context.respond_to?(:size) && context.respond_to?(:count)
          raise "Count context must be enumerable"
        end

        context.count {|item| execute(item, field)}
      end

      def invert(context)
        !context
      end

      def unique(context, field)
        collect(context, field).uniq
      end

      def average(context, params)
        if context.respond_to?(:collect) && context.respond_to?(:size) && params.size == 1
          count = context.size
        else
          count = params.size
        end
        
        return 0.0 if count == 0
        sum(context, params).to_f / count.to_f
      end

      def present(context)
        context.present?
      end
      
      def blank(context)
        context.blank?
      end

      def sum(context, params)
        if context.respond_to?(:collect) && params.size == 1
          collect(context, params.first).inject(&:+)
        else
          params.collect {|method| execute(context, method)}.inject(&:+)
        end
      end

      def round(context)
        context.to_f.round
      end

      def binary_if(context, condition, true_exp, false_exp)
        if execute(context, condition)
          execute(context, true_exp) if true_exp
        else
          execute(context, false_exp) if false_exp
        end
      end

      def strip(context)
        context.to_s.strip
      end
      
      def deliver_email(context, name, hash)
        raise "Context of deliver_email must respond to site" unless context.respond_to?(:site)
        email = context.site.emails[execute(context, name)]
        email.deliver(execute(context, hash))
      end
      
      def call_api(context, name, hash)
        raise "Context of call_api must respond to site" unless context.respond_to?(:site)
        api = context.site.api_calls[execute(context, name)]
        api.call(execute(context, hash))
      end

      # TODO: currently substitutions that span multiple record will fail e.g
      # {{name}} will work but {{record.name}} won't
      def format(context, str)
        str = execute(context, str)
        str.gsub(/{{\s*(\w+)\s*}}/) do |field|
          context.get($1)
        end
      end
      
      # TODO: add call styles to min and max:
      # items.min(index)
      # items.collect(index).min
      # min(one, two)
      def min(context, one, two)
        [execute(context, one), execute(context, two)].min        
      end
      
      def max(context, one, two)
        [execute(context, one), execute(context, two)].max
      end
  end
end
