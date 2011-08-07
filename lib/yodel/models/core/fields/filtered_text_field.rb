class FilteredTextField < TextField
  include FilterMixin
end

Field::TYPES['filtered_text'] = FilteredTextField
