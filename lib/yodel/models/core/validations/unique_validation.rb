class UniqueValidation < Validation
  validate do
    invalidate_with("must be unique") if record.model.exists?(field.name => value, :_id.ne => record.id)
  end
end
