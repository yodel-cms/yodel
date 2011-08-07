class UniqueValidation < Validation
  def self.validate(params, field, name, value, record, errors)
    errors[field.name] << new(params) if record.model.exists?(field.name => value, :_id.ne => record.id)
  end

  def describe
    "must be unique"
  end
end
