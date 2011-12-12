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
    @query ||= begin
      query_type = type || site.records
      q = query_type.where(show_in_search: true)
    
      # constant constraints
      conditions.each do |condition|
        q = add_condition(q, query_type, condition.name, condition.operator, condition.value)
      end
    
      # user conditions
      user_conditions.each do |condition|
        param_name = condition.as || condition.name
        q = add_condition(q, query_type, condition.name, condition.operator, params[param_name])
      end
    
      # add other optional search parameters
      q = q.sort(sort || params['sort']) if sort || params['sort']
      q = q.limit(limit || params['limit'].to_i) if limit || params['limit']
      q = q.skip(skip || params['skip'].to_i) if skip || params['skip']
      q
    end
  end
  
  def add_condition(q, type, field, operator, value)
    return q if value.blank?
    operator = OPERATOR_METHODS[operator]
    field = field.to_sym
    
    if type && type.all_record_fields[field.to_s]
      value = type.all_record_fields[field.to_s].from_json(value, type)
    end
    
    if operator
      q.where(field.send(operator) => value)
    else
      q.where(field => value)
    end
  end
  
  # True if the request contains any of the parameters 
  def user_query?
    user_conditions.any? {|condition| params[condition.as ? condition.as : condition.name].present?}
  end
end
