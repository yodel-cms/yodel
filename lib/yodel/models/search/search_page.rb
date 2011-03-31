module Yodel
  class SearchPage < Page
    OPERATOR_METHODS = {
      'Equals' => nil,
      'Not Equal' => :ne,
      'Greater Than' => :gt,
      'Less Than' => :lt,
      'Greater Than or Equal To' => :gte,
      'Less Than or Equal To' => :lte,
      'In' => :in
    }
    
    def query
      q = (type || site.records).where(show_in_search: true)
      
      # constant constraints
      conditions.each do |condition|
        q = add_condition(q, condition.field, condition.operator, condition.value, condition.type)
      end
      
      # user conditions
      user_conditions.each do |condition|
        param_name = condition.as || condition.field
        q = add_condition(q, condition.field, condition.operator, params[param_name], condition.type)
      end
      
      # add other optional search parameters
      q = q.sort(sort || params['sort']) if sort || params['sort']
      q = q.limit(limit || params['limit'].to_i) if limit || params['limit']
      q = q.skip(skip || params['skip'].to_i) if skip || params['skip']
      q
    end
    
    def add_condition(q, field, operator, value, type)
      return q if value.blank?
      operator = OPERATOR_METHODS[operator]
      field = field.to_sym
      
      # process value - 'null' == nil, and the in operator works on arrays
      value = Object.module_eval(type).from_html_field(nil, nil, value)
      return q if value.nil?
      if operator == :in
        value = value.to_s.split(' ').reject(&:blank?).collect(&:downcase)
      end
      
      if operator
        q.where(field.send(operator) => value)
      else
        q.where(field => value)
      end
    end

    def get_value(record, field)
      return record.send(field) if record.respond_to? field
      return record.get_field(field) if record.respond_to? :get_field
      nil
    rescue
      nil
    end

    # FIXME: handle id -> _id
    # FIXME: handle fields with more than 2 components: field.other.other
    # Search pages have a list of fields to be sent back as part of json requests;
    # only send back that list of fields, and process the values. Field names can
    # also include full stops. If the value of the first component is a record,
    # the second component is sent as the value (i.e author.name =>
    # record.author.name), If the value is an array, the value returned by each
    # related record is returned, as an array of values (children.title =>
    # children.collect(&:title))
    def record_to_json(record)
      json_fields.each_with_object({}) do |field, json|
        if field.include? '.'
          field1, field2 = field.split('.')
          value = get_value(record, field1)
          if value.is_a? Array
            if value.first.is_a? Record
              field_options = value.first.field_options(field2)
            else
              field_options = record.field_options(field1).fields.detect {|efield| efield['name'] == field2}
              field_options = OpenStruct.new(field_options) if field_options.is_a? Hash
            end
            value = value.collect {|related| get_value(related, field2)}
          elsif value.is_a? Yodel::Record
            field_options = value.field_options(field2)
            value = get_value(value, field2)
          end
        else
          field_options = record.field_options(field)
          value = get_value(record, field)
        end
        
        field = field.gsub('.', '__')
        unless value.is_a? Array
          json[field] = Object.module_eval(field_options.type).to_json(record, field_options, value)
        else
          json[field] = []
          type = Object.module_eval(field_options.type)
          value.each do |related_value|
            json[field] << type.to_json(record, field_options, related_value)
          end
        end
      end
    end

    respond_to :get do
      with :json do
        return unless user_permitted_to?(:view)
        {results: query.all.collect {|record| record_to_json(record)}}
      end
    end
  end
end
