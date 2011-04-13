module Yodel
  class FilteredStringField < StringField
    include Yodel::FilterMixin
  end
end
