class AttachmentField < Field
  def default_input_type
    :file
  end
  
  def default
    Attachment.new({}, nil, self).to_hash
  end
  
  def untypecast(value, record)
    # expecting an Attachment object, or a hash of the original data
    value.to_hash
  end
  
  def typecast(value, record)
    Attachment.new(value, record, self)
  end

  def json_action(action, value, record)
    original = record.get(name)
    case action
    when 'set'
      return if value.nil?
      original.set_file(value)
      record.set_raw(name, original.to_hash)
    when 'clear'
      original.remove_files
      record.set_raw(name, nil)
    end
    record.changed!(name)
  end
  
  def from_json(value, record)
    original = record.get(name)
    original.set_file(value)
    original
  end
  
  def after_destroy(record)
    if record.get(name).is_a?(Attachment)
      record.get(name).remove_files
    end
  end
end

Field::TYPES['attachment'] = AttachmentField
