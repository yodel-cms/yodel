class ImageField < AttachmentField
  def default_input_type
    :image
  end
  
  def default
    Image.new({}, nil, self).to_hash
  end
  
  def typecast(value, record)
    Image.new(value, record, self)
  end
end

Field::TYPES['image'] = ImageField
