module Yodel
  class Function
    attr_accessor :instructions, :source
    
    def initialize(source)
      @source = source
      @instructions = compile(source)
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
    PARAM_DELIM_TOKEN   = ','
    DOUBLE_QUOTE_TOKEN  = '"'
    SINGLE_QUOTE_TOKEN  = "'"

    def compile(source)
      tokens = source.scan(/\w+|\.|\(|\)|,|"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'/)
      parse(tokens)
    end

    def parse(tokens)
      params = false
      chain  = false
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
        when PARAM_DELIM_TOKEN
          if params
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
    def execute(context, instruction=nil)
      instruction ||= self.instructions.first
      name, *params = instruction

      case name
      when 'chain'
        chain(context, params)
      when 'field'
        get_field(context, params.first)
      when 'collect'
        collect(context, params.first)
      when 'majority'
        majority(context, params.first)
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
        set_field(context, params[0], params[1])
        
      # literals
      when 'string'
        params.first
      end
    end
    
    protected
      def chain(context, methods)
        methods.each do |method|
          context = execute(context, method)
        end
        context
      end

      def get_field(context, name)
        name == 'self' ? context : context.get(name)
      end
      
      def set_field(context, field, value)
        field = execute(context, field)
        value = execute(context, value)
        context.set(field, value)
      end

      def collect(context, field)
        raise "Context to collect must respond to collect" unless context.respond_to?(:collect)
        context.collect {|item| execute(item, field)}
      end

      def majority(context, field)
        unless context.respond_to?(:size) && context.respond_to?(:count)
          raise "Majority context must be enumerable"
        end

        valid = context.count {|item| execute(item, field)}
        valid >= (context.size - valid)
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
          execute(context, true_exp)
        else
          execute(context, false_exp)
        end
      end

      def strip(context)
        context.to_s.strip
      end

      # TODO: currently substitutions that span multiple record will fail e.g
      # {{name}} will work but {{record.name}} won't
      def format(context, str)
        str = execute(context, str)
        str.gsub(/{{\s*(\w+)\s*}}/) do |field|
          context.get($1)
        end
      end
  end
end
