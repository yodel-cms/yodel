class EmailField < StringField
  
  def validate(record, errors)
    EmailAddressValidation.validate(nil, self, name, record.get(name), record, errors)
    super
  end
  
end

Field::TYPES['email'] = EmailField
