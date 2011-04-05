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
  end
end
