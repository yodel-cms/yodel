class FilteredStringField < StringField
  include FilterMixin
end

Field::TYPES['filtered_string'] = FilteredStringField
