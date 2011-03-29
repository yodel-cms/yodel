class StoreMany < Array
  def self.from_mongo(record, field, value)
    return [] unless value.respond_to?(:collect)
    model = record.site.model(field.of)
    value.collect {|id| model.find(id)}
  end
  
  # FIXME: need to ensure the values are instances of the model
  def self.to_mongo(record, field, value)
    return [] unless value.respond_to?(:collect)
    value.collect {|record| record.nil? ? nil : record.id}.compact
  end
  
  def self.from_json(record, field, value)
    from_html_field(record, field, value)
  end
  
  def self.to_json(record, field, value)
    return [] unless value.respond_to?(:collect)
    value.collect(&:to_s)
  end
  
  # FIXME: need to ensure the values are instances of the model
  def self.from_html_field(record, field, value)
    return [] unless value.respond_to?(:collect)
    value.collect do |id|
      begin
        BSON::ObjectId.new(id)
      rescue
        nil
      end
    end.compact
  end
  
  def self.to_html_field(record, field, value)
    model = record.site.model(field.to)
    return nil if model.nil?
    value = value || []
    
    select_options = model.all.collect do |record|
      options = {value: record.id.to_s}
      options[:selected] = 'selected' if value.include?(record.id)
      Hpricot::Elem.new('option', options, [Hpricot::Text.new(record.name)])
    end
    
    Hpricot::Elem.new('select', {name: field.name, multiple: 'multiple'}, select_options)
  end
end
