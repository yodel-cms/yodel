class RecordModelMigration < Migration
  def self.up(site)
    records = Model.new(site, name: 'Record')
    records.modify do |records|
      # identity, hierarchy and search
      add_many  :children, model: :record, foreign_key: 'parent', order: 'index asc'
      add_field :index, :integer, validations: {required: {}}
      add_one   :owner, model: :user
      add_field :name, :string
      add_field :show_in_search, :boolean, default: true
      add_field :search_keywords, :array, of: :string
      add_field :search_title, :string

      # modelling
      add_one   :eigenmodel, model: :model, destroy: true
      add_one   :parent, model: :record, index: true
      add_one   :model, index: true
      records.descendants = [records]
    end

    site.model_types['records'] = records.id
    site.model_plural_names['Record'] = 'records'
    site.save
  end
  
  def self.down(site)
    site.records.destroy
  end
end
