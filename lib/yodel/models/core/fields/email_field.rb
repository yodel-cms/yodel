class EmailField < StringField
  def validations
    super.merge({email_address: {}})
  end
end

Field::TYPES['email'] = EmailField
