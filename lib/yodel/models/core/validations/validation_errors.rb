class ValidationErrors
  attr_reader :record, :errors, :embedded_errors, :field, :value, :params, :parent_field
  def initialize(record)
    @record = record
    @embedded_errors = {}
    @errors = Hash.new do |hash, key|
      hash[key] = []
    end
  end
  
  def run_validations(fields, validations_method=:validations, values=nil, parent_field=nil)
    @parent_field = parent_field
    fields.each_with_index do |field, index|
      @field = field
      validations = @field.send(validations_method)
      next if validations.blank?
      @value = values ? values[index] : record.get(field.name)
      
      validations.each do |type, params|
        @params = params
        # TODO: catch when type is an unknown validation
        send("validate_#{type}")
      end
    end
  end
  
  def inspect
    all_record_errors_to_hash.inspect
  end
  
  def [](name)
    @errors[name]
  end
  
  def key?(name)
    @errors.key?(name)
  end
  
  def empty?
    @errors.empty? && @embedded_errors.empty?
  end
  
  def embedded_errors?
    @embedded_errors.empty?
  end
  
  def clear
    @errors.clear
    @embedded_errors.clear
  end
  
  def to_hash
    @errors
  end
  
  def all_record_errors_to_hash
    return @embedded_errors if @errors.empty?
    @embedded_errors.merge({@record.id.to_s => @errors})
  end
  
  def to_json(*a)
    all_record_errors_to_hash.to_json(*a)
  end
  
  private
    def invalidate_with(description)
      if @parent_field
        @errors[@parent_field.name] << "#{field.name.humanize} #{description}"
      else
        @errors[@field.name] << description
      end
    end
    
    def add_embedded_errors(embedded_record)
      if embedded_record.errors.embedded_errors?
        @embedded_errors.merge!(embedded_record.errors.embedded_errors)
      end
      @embedded_errors[embedded_record.id.to_s] = embedded_record.errors.to_hash
    end
end
