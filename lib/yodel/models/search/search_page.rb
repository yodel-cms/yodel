module Yodel
  class SearchPage < Page
    OPERATOR_METHODS = {
      'Equals' => :eq,
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
        q = add_condition(q, condition['field'], condition['operator'], condition['value'])
      end
      
      # user conditions
      user_conditions.each do |condition|
        q = add_condition(q, condition['field'], condition['operator'], params[condition['field']])
      end
      
      # add other optional search parameters
      q = q.sort(sort || params['sort']) if sort || params['sort']
      q = q.limit(limit || params['limit'].to_i) if limit || params['limit']
      q = q.skip(skip || params['skip'].to_i) if skip || params['skip']
      q
    end
    
    def add_condition(q, field, operator, value)
      operator = OPERATOR_METHODS[operator]
      field = field.to_sym
      
      # process value - 'null' == nil, and the in operator works on arrays
      return q value.nil?
      if operator == :in
        value = value.to_s.split(' ').reject(&:blank?).collect(&:downcase)
      else
        value = nil if value == 'null'
      end
      
      q.where(field.send(operator) => value)
    end

    
    respond_to :get do
      with :json do
        {query: query.inspect, results: query.all.collect(&:to_json)}
      end
    end
  end
end
