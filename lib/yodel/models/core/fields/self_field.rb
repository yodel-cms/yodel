module Yodel
  class SelfField < Field
    def strip_nil?
      true
    end

    def validate(record, errors)
      # noop
    end

    def typecast(value, record)
      record
    end

    def untypecast(value, record)
      nil
    end

    def from_json(value, record)
      nil
    end
  end
end
