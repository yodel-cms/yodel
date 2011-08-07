class AliasField < Field    
  # FIXME: assignments don't work; alias = val won't be saved
  # FIXME: changes to the original value aren't observed;
  # original = val_1, alias => val_1; original = val_2; alias => val_1
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
    field_name = @options['of'].to_s
    raise InvalidField, "Alias fields must have a from property" if field_name.blank?
    record.get(field_name)
  end

  def untypecast(value, record)
    nil
  end

  def from_json(value, record)
    nil
  end
end
