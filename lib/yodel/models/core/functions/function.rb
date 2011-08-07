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
  def execute(context, instruction=nil, parent_context=nil)
    instruction ||= self.instructions.first
    name, *params = instruction
    parent_context ||= context

    case name
    when 'chain'
      chain(context, parent_context, params)
    when 'field'
      get_field(context, parent_context, params.first)
    when 'find'
      find_record(context, parent_context, params[0], params[1])
    when 'changed'
      changed(context, parent_context, params.first)
    when 'previous_value'
      previous_value(context, parent_context, params.first)
    when 'collect'
      collect(context, parent_context, params.first)
    when 'majority'
      majority(context, parent_context, params.first)
    when 'count'
      count(context, parent_context, params.first)
    when 'invert'
      invert(context)
    when 'unique'
      unique(context, parent_context, params.first)
    when 'average'
      average(context, parent_context, params)
    when 'as_a_percentage_of'
      as_a_percentage_of(context, parent_context, params.first)
    when 'present'
      present(context)
    when 'blank'
      blank(context)
    when 'sum'
      sum(context, parent_context, params)
    when 'subtract'
      subtract(context, parent_context, params)
    when 'multiply'
      multiply(context, parent_context, params)
    when 'round'
      round(context)
    when 'if'
      binary_if(context, parent_context, params[0], params[1], params[2])
    when 'greater_than'
      greater_than(context, parent_context, params.first)
    when 'greater_than_or_equal_to'
      greater_than_or_equal_to(context, parent_context, params.first)
    when 'less_than'
      less_than(context, parent_context, params.first)
    when 'less_than_or_equal_to'
      less_than_or_equal_to(context, parent_context, params.first)
    when 'not_equal'
      not_equal(context, parent_context, params.first)
    when 'and'
      binary_and(context, parent_context, params[0], params[1])
    when 'or'
      binary_or(context, parent_context, params[0], params[1])
    when 'include'
      set_include(context, parent_context, params.first)
    when 'strip'
      strip(context)
    when 'format'
      format(context, parent_context, params.first)
    when 'set'
      set_field(context, parent_context, params[0], params[1])
    when 'update'
      update_field(context, parent_context, params[0], params[1])
    when 'min'
      min(context, parent_context, params[0], params[1])
    when 'max'
      max(context, parent_context, params[0], params[1])
    when 'increment'
      increment(context, parent_context, params[0], params[1])
    when 'complement'
      complement(context, parent_context, params[0], params[1])
    when 'each'
      each(context, parent_context, params.first)
    when 'deliver'
      deliver_email(context, parent_context, params[0], params[1])
    when 'call_api'
      call_api(context, parent_context, params[0], params[1])
      
    # literals
    when 'string'
      params.first
    when 'int'
      params.first.to_i
    when 'hash'
      Hash[params.collect {|entry| execute(context, entry, parent_context)}]
    when 'entry'
      [execute(context, params.first, parent_context), execute(context, params.last, parent_context)]
    end
  end
  
  protected
    def chain(context, parent_context, methods)
      #parent_context = context
      methods.each do |method|
        context = execute(context, method, parent_context)
      end
      context
    end

    def get_field(context, parent_context, name)
      case name
      when 'self'
        context
      when 'root'
        parent_context
      # TODO: these should be caught as booleans instead of being treated as field names
      when 'true'
        true
      when 'false'
        false
      else
        context.get(name)
      end
    rescue
      nil
    end
    
    def find_record(context, parent_context, model_name, key)
      raise "Parent context of find_record must respond to site" unless parent_context.respond_to?(:site)
      model_name = execute(context, model_name, parent_context)
      key = execute(context, key, parent_context)
      model = parent_context.site.model_by_plural_name(model_name)
      
      if key == 'id'
        value = BSON::ObjectId.from_string(context)
      else
        value = context
      end
      
      model.where(key => value).first
    end
    
    def previous_value(context, parent_context, name)
      context.field_was(execute(context, name, parent_context))
    end
    
    # TODO: change format from changed('name') to name.changed
    def changed(context, parent_context, name)
      context.changed?(execute(context, name, parent_context))
    end
    
    def set_field(context, parent_context, field, value)
      field = execute(parent_context, field, parent_context)
      value = execute(parent_context, value, parent_context)
      context.set(field, value)
    end
    
    def update_field(context, parent_context, field, value)
      set_field(context, parent_context, field, value)
      context.save
    end
    
    def increment(context, parent_context, field, value)
      field = execute(context, field, parent_context)
      value = execute(context, value, parent_context)
      context.increment!(field, value)
    end

    def collect(context, parent_context, field)
      raise "Context to collect must respond to collect" unless context.respond_to?(:collect)
      context.collect {|item| execute(item, field, parent_context)}
    end
    
    def each(context, parent_context, statement)
      raise "Context to each must respond to each" unless context.respond_to?(:each)
      context.each {|item| execute(item, statement, parent_context)}
    end

    def majority(context, parent_context, field)
      unless context.respond_to?(:size) && context.respond_to?(:count)
        raise "Majority context must be enumerable"
      end

      valid = context.count {|item| execute(item, field, parent_context)}
      valid >= (context.size - valid)
    end
    
    def count(context, parent_context, field)
      unless context.respond_to?(:size) && context.respond_to?(:count)
        raise "Count context must be enumerable"
      end
      
      if field.nil?
        context.size
      else
        context.count {|item| execute(item, field, parent_context)}
      end
    end

    def invert(context)
      !context
    end

    def unique(context, parent_context, field)
      collect(context, parent_context, field).uniq
    end

    def average(context, parent_context, params)
      if context.respond_to?(:collect) && context.respond_to?(:size) && params.size == 1
        count = context.size
      else
        count = params.size
      end
      
      return 0.0 if count == 0
      sum(context, parent_context, params).to_f / count.to_f
    end
    
    def as_a_percentage_of(context, parent_context, count)
      count = execute(context, count, parent_context)
      context = context.to_f
      count = count.to_f
      
      if context == 0 || count == 0
        return 0
      else
        (context / count) * 100
      end
    end

    def present(context)
      context.present?
    end
    
    def blank(context)
      context.blank?
    end

    def sum(context, parent_context, params)
      if context.respond_to?(:collect) && params.size == 1
        collect(context, parent_context, params.first).compact.inject(&:+)
      else
        params.collect {|method| execute(context, method, parent_context)}.compact.inject(&:+)
      end
    end
    
    def subtract(context, parent_context, params)
      if context.respond_to?(:collect) && params.size == 1
        collect(context, parent_context, params.first).compact.inject(&:-)
      else
        params.collect {|method| execute(context, method, parent_context)}.compact.inject(&:-)
      end
    end
    
    def multiply(context, parent_context, params)
      if context.respond_to?(:collect) && params.size == 1
        collect(context, parent_context, params.first).compact.inject(&:*)
      else
        params.collect {|method| execute(context, method, parent_context)}.compact.inject(&:*)
      end
    end
    
    def complement(context, parent_context, set1, set2)
      set1 = execute(context, set1, parent_context)
      set2 = execute(context, set2, parent_context)
      raise "Sets must be iterable" unless set1.respond_to?(:to_a) && set2.respond_to?(:to_a)
      set2.to_a - set1.to_a
    end
    
    def set_include(context, parent_context, item)
      item = execute(context, item, parent_context)
      raise "Context must respond to include?" unless context.respond_to?(:include?)
      context.include?(item)
    end

    def round(context)
      context.to_f.round
    end

    def binary_if(context, parent_context, condition, true_exp, false_exp)
      if execute(context, condition, parent_context)
        execute(context, true_exp, parent_context) if true_exp
      else
        execute(context, false_exp, parent_context) if false_exp
      end
    end
    
    def greater_than(context, parent_context, value)
      value = execute(parent_context, value, parent_context)
      context > value
    end
    
    def less_than(context, parent_context, value)
      value = execute(parent_context, value, parent_context)
      context < value
    end
    
    def greater_than_or_equal_to(context, parent_context, value)
      value = execute(parent_context, value, parent_context)
      context >= value
    end
      
    def less_than_or_equal_to(context, parent_context, value)
      value = execute(parent_context, value, parent_context)
      context <= value
    end
    
    def not_equal(context, parent_context, value)
      value = execute(parent_context, value, parent_context)
      context != value
    end
    
    def binary_and(context, parent_context, operand1, operand2)
      operand1 = execute(context, operand1, parent_context)
      
      if operand2
        operand2 = execute(context, operand2, parent_context)
        operand1 && operand2
      else
        context && operand1
      end
    end
    
    def binary_or(context, parent_context, operand1, operand2)
      operand1 = execute(context, operand1, parent_context)
      
      if operand2
        operand2 = execute(context, operand2, parent_context)
        operand1 || operand2
      else
        context || operand1
      end
    end

    def strip(context)
      context.to_s.strip
    end
    
    def deliver_email(context, parent_context, name, hash)
      raise "Context of deliver_email must respond to site" unless context.respond_to?(:site)
      email = context.site.emails[execute(context, name, parent_context)]
      email.deliver(execute(context, hash, parent_context))
    end
    
    def call_api(context, parent_context, name, hash)
      raise "Context of call_api must respond to site" unless context.respond_to?(:site)
      api = context.site.api_calls[execute(context, name, parent_context)]
      api.call(execute(context, hash, parent_context))
    end

    def format(context, parent_context, str)
      str = execute(context, str, parent_context)
      str.gsub(/{{\s*([\w\.]+)\s*}}/) do |field|
        fn = Function.new($1)
        fn.execute(context, nil, parent_context)
      end
    end
    
    # TODO: add call styles to min and max:
    # items.min(index)
    # items.collect(index).min
    # min(one, two)
    def min(context, parent_context, one, two)
      [execute(context, one, parent_context), execute(context, two, parent_context)].min        
    end
    
    def max(context, parent_context, one, two)
      [execute(context, one, parent_context), execute(context, two, parent_context)].max
    end
end
