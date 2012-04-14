class LengthValidation < Validation
  validate do
    min, max = params['length']
    size = value.try(:size) || 0
  
    if min == 0
      valid = (size <= max)
    elsif max == 0
      valid = (size >= min)
    else
      valid = (size >= min) && (size <= max)
    end
  
    unless valid
      if min == 0
        invalidate_with("is too long (maximum length is #{max})")
      elsif max == 0
        invalidate_with("is too short (minimum length is #{min})")
      else
        invalidate_with("must be between #{min} and #{max}")
      end
    end
  end
end
