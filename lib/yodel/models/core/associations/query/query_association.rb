module QueryAssociation
  include RecordAssociation
  
  def initialize(name, options={})
    super
    options['where'] = Plucky::CriteriaHash.new(options['where']).to_hash if options['where']
  end
  
  def validate(record, errors)
    # noop
  end
  
  def default
    nil
  end
  
  def strip_nil?
    true
  end
  
  def associate(associated_record, store, record)
    associated_record.set_meta(foreign_key(record), association_value(record))
    associated_record.save_without_validation
  end
  
  def unassociate(associated_record, store, record)
    return unless associated_record.get_meta(foreign_key) == association_value(record)
    associated_record.set_meta(foreign_key(record), nil)
    associated_record.save_without_validation
  end
  
  protected
    def clear(store, record)
      all(store, record).each {|associated_record| unassociate(associated_record, store, record)}
    end
    
    def all(store, record)
      scope(record).all
    end
    
    def scope(record)
      if options['through']
        through_query = record.field(options['through'].to_s).scope(record).only('_id')
        cursor = Record.collection.find(through_query.criteria.to_hash, through_query.options.to_hash)
        ids = cursor.to_a.collect {|doc| doc['_id']}
        scope = record.site.model(model_name).where(foreign_key(record) => ids)
        
      elsif options['extends']
        # to allow extended associations to override the association's original query, remove
        # any conditions which occur in the additional criteria
        scope = record.field(options['extends'].to_s).scope(record)
        if options['where']
          options['where'].keys.each do |field|
            scope.criteria.source.delete(field)
          end
        end

      else
        scope = record.site.model(model_name).where(foreign_key(record) => association_value(record))
      end

      scope = scope.where(options['where'].to_hash) if options['where']
      scope = scope.sort(options['order'].to_s) if options['order']
      scope = scope.limit(options['limit'].to_i) if options['limit']
      scope = scope.skip(options['skip'].to_i) if options['skip']
      scope
    end
    
    def associated(store, record)
      record.site.model(model_name).first(foreign_key(record) => association_value(record))
    end
    
    def association_value(record)
      if options['value_field']
        field = record.fields[options['value_field']]
        raise new InvalidField("Unknown field '#{options['value_field']}' specified in association '#{name}' of model '#{record.model.name}'") if field.nil?
        field.untypecast(record.send(options['value_field']), record)
      else # id
        record.id
      end
    end
end
