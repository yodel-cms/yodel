module PrimaryKeyFactory
  # The default mongo primary key factory (BSON::ObjectId) creates ids
  # with symbol keys. Yodel uses string keys (since records are retrieved
  # with string keys) so Yodel mongo collections use this pk factory instead.
  def self.create_pk(doc)
    doc.has_key?('_id') ? doc : doc.merge!('_id' => self.pk)
  end
  
  def self.pk
    BSON::ObjectId.new
  end
end
