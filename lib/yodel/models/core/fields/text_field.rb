module Yodel
  class TextField < StringField
    def default_input_type
      :textarea
    end
  end
end
