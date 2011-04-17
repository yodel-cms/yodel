module Yodel
  class PasswordField < StringField
    undef search_terms_set
  end
end
