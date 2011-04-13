module Yodel
  class TagsField < ArrayField
    def from_json(value, record)
      value.to_s.split(',').map(&:strip).reject(&:blank?).uniq
    end
  end
end
