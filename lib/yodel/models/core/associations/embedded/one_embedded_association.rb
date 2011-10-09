class OneEmbeddedAssociation < Association
  include EmbeddedAssociation
  include OneAssociation
  
  # remove OneAssociation's destroy behaviour since embedded
  # records are destroyed as part of the parent anyway
  undef :before_destroy
  
  def search_terms_set(record)
    record.get(name).search_terms
  end
  
  def default
    @options['default'] || EmbeddedRecord.new(self, nil).default_values
  end
  
  def options
    super.merge({'type' => 'one_embedded'})
  end
  
  def save(embedded_record, parent_record)
    # noop
  end

  def destroy(embedded_record, parent_record)
    embedded_record.initialize(self, parent_record)
    parent_record.changed!(name)
  end
  
  def untypecast(value, record)
    return {} unless value.is_a?(EmbeddedRecord)
    value.save
    value.values
  end
  
  private
    def associated(store, record)
      store = {} unless store.is_a?(Hash)
      EmbeddedRecord.new(self, record, store, false)
    end
    
    def associate(embedded_record, store, record)
      raise "Associated record must be an Embedded Record" unless embedded_record.is_a?(EmbeddedRecord)
      embedded_record.save
      record.set(name, embedded_record)
    end
end

Field::TYPES['one_embedded'] = OneEmbeddedAssociation
