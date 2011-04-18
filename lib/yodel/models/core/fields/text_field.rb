module Yodel
  class TextField < StringField
    def default_input_type
      :text_area
    end
  end
end
