module Yodel
  class PasswordField < StringField
    undef search_terms_set
    def default_input_type
      :password
    end
    
    def validate(record, errors)
      Yodel::PasswordConfirmationValidation.validate(nil, self, name, nil, record, errors)
      super
    end
    
    def from_json(value, record)
      if value.blank?
        throw :ignore_value
      else
        value.to_s
      end
    end
  end
end
