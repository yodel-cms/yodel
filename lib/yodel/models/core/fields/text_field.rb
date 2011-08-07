class TextField < StringField
  def default_input_type
    :textarea
  end
end

Field::TYPES['text'] = TextField
