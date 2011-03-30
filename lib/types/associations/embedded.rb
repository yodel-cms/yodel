class Embedded
  extend YodelTypeInterface
  
  def self.from_mongo(record, field, value)
    clean_document(record, field, value, :from_mongo).collect do |values|
      OpenStruct.new(values).tap do |record_object|
        record_object.site = record.site
      end
    end
  end
  
  def self.to_mongo(record, field, value)
    clean_document(record, field, value, :to_mongo)
  end
  
  def self.from_json(record, field, value)
    clean_document(record, field, value, :from_json)
  end
  
  def self.to_json(record, field, value)
    clean_document(record, field, value, :to_json)
  end
  
  def self.from_html_field(record, field, value)
    clean_document(record, field, value, :from_html_field)
  end
  
  def self.to_html_field(record, field, value)
    # FIXME: unimplemented
    raise "unimplemented"
  end
  
  private
    def self.clean_document(record, field, value, method)
      return [] unless value.respond_to?(:collect)
      fields = field.fields.collect {|options| OpenStruct.new(options)}
      
      value.collect do |typecast_document|
        typecast_document.stringify_keys! if typecast_document.is_a?(Hash)
        
        if typecast_document.is_a?(Hash)
          fields.each_with_object({}) do |field, document|
            document[field.name] = Object.module_eval(field.type).send(method, record, field, typecast_document[field.name])
          end
        else
          fields.each_with_object({}) do |field, document|
            document[field.name] = Object.module_eval(field.type).send(method, record, field, typecast_document.send(field.name))
          end
        end
      end
    end
end
