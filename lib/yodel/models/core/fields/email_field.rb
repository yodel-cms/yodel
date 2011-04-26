module Yodel
  class EmailField < StringField
    
    def validate(record, errors)
      Yodel::EmailAddressValidation.validate(nil, self, name, record.get(name), record, errors)
      super
    end
    
  end
end
