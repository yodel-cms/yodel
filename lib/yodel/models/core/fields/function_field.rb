class FunctionField < Field
  def strip_nil?
    true
  end
  
  def default_input_type
    nil
  end

  def validate(record, errors)
    # noop
  end

  def typecast(value, record)
    compiled_fn = Function.new(@options['fn'])
    compiled_fn.execute(record)
  end

  def untypecast(value, record)
    nil
  end

  def from_json(value, record)
    nil
  end
end

Field::TYPES['function'] = FunctionField
