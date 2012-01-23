class BooleanField < Field
  def default_input_type
    :checkbox
  end
  
  def json_action(action, value, record)
    case action
    when 'set'
      record.set_raw(name, !!value)
    when 'toggle'
      record.set_raw(name, !record.get(name))
    end
    
    record.changed!(name)
  end

  def from_json(value, record)
    if value == 'true'
      true
    elsif value == 'false'
      false
    else
      !!value
    end
  end
end

Field::TYPES['boolean'] = BooleanField
