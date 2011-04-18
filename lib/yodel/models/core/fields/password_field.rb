module Yodel
  class PasswordField < StringField
    undef search_terms_set
    def default_input_type
      :password
    end
  end
end
