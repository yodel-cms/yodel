module OneAssociation
  def search_terms_set(record)
    return [] unless include_in_search_keywords?
    record.get(name).try(:search_terms) || []
  end
  
  def before_destroy(record)
    if @options['destroy'] == true
      record.get(name).try(:destroy)
    end
  end
  
  def typecast(value, record)
    return default if value.blank?
    associated(value, record)
  end
  
  private
    def clear(store, record)
      unassociate(associated(store, record), store, record)
    end
end
