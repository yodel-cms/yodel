class ManyEmbeddedAssociation < Association
  include EmbeddedAssociation
  include ManyAssociation
  
  # remove ManyAssociation's destroy behaviour since embedded
  # records are destroyed as part of the parent anyway
  undef :before_destroy
  
  def search_terms_set(record)
    record.get(name).collect do |embedded_record|
      embedded_record.search_terms
    end.flatten
  end
  
  def options
    super.merge({'type' => 'many_embedded'})
  end
  
  def save(embedded_record, parent_record)
    if embedded_record.new?
      parent_record.get(name) << embedded_record
    end
  end

  def destroy(embedded_record, parent_record)
    parent_record.get(name).delete(embedded_record)
  end
  
  def associate(embedded_record, store, record)
    raise "Associated record must be an Embedded Record" unless embedded_record.is_a?(EmbeddedRecord)
    embedded_record.save
    store << embedded_record.values
  end
  
  def unassociate(embedded_record, store, record)
    store.delete(embedded_record)
  end
  
  def untypecast(value, record)
    return nil if value.blank?
    raise "ManyEmbeddedAssociation values must be enumerable (#{name})" unless value.respond_to?(:each)
    
    store = record.get_raw(name)
    clear(store, record)
    value.each do |associated_record|
      associate(associated_record, store, record)
    end
    store
  end
  
  def default
    @options['default'] || []
  end
  
  def typecast(value, record)
    return EmbeddedRecordArray.new(record, self, []) if value.blank?
    raise "ManyEmbedded values must be enumerable (#{name})" unless value.respond_to?(:each)
    EmbeddedRecordArray.new(record, self, all(value, record))
  end
  
  def from_json(value, record)
    # TODO: change to constructing a new array here instead of removing elements at the end
    store = record.get(name)
    existing_records = store.each_with_object({}) {|record, ids| ids[record.id.to_s] = record}
    
    # update and add existing/new records
    value.each do |new_record|
      next unless new_record.is_a?(Hash)
      new_record_id = new_record['_id']
      new_record.delete('_id')
      if existing_records.key?(new_record_id)
        existing_records[new_record_id].from_json(new_record)
        existing_records.delete(new_record_id)
      else
        process_json_item(new_record, store, record).save
      end
    end
    
    # any remaining ids in existing_records were deleted
    existing_records.values.each(&:destroy)
    record.get(name)
  end
end

Field::TYPES['many_embedded'] = ManyEmbeddedAssociation
