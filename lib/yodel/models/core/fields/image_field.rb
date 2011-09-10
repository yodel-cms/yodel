class ImageField < AttachmentField
  def default_input_type
    :image
  end
  
  def typecast(value, record)
    Image.new(value, record, self)
  end
end

Field::TYPES['image'] = ImageField
