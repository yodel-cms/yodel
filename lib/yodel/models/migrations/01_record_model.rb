class RecordModelMigration < Migration
  def self.up(site)
    records = Model.new(site, name: 'Record')
    records.modify do |records|
      # identity, hierarchy and search
      add_many  :children, model: :record, foreign_key: 'parent', order: 'index asc', display: false
      add_field :index, :integer, validations: {required: {}}, display: false
      add_one   :owner, model: :user, display: false
      add_field :name, :string
      add_field :show_in_search, :boolean, default: true, section: 'Options'
      add_field :search_keywords, :array, of: :string, display: false
      add_field :search_title, :alias, of: :title, display: false

      # modelling
      add_one   :eigenmodel, model: :model, destroy: true, display: false
      add_one   :parent, model: :record, index: true, display: false
      add_one   :model, index: true, display: false
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
