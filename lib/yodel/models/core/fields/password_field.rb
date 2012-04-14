class PasswordField < StringField
  undef search_terms_set
  def default_input_type
    :password
  end
  
  def from_json(value, record)
    if value.blank?
      throw :ignore_value
    else
      value.to_s
    end
  end
  
  def validations
    super.merge({password_confirmation: {}})
  end
end

Field::TYPES['password'] = PasswordField
