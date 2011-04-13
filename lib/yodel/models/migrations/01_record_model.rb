class RecordModelMigration < Yodel::Migration
  def self.up(site)
    records = Yodel::Model.new(site, name: 'Record')
    records.modify do |records|
      # identity, hierarchy and search
      add_field :name, :string, required: true
      add_field :index, :integer, required: true
      add_field :show_in_search, :boolean, default: true
      add_field :search_keywords, :array, of: :string
      add_field :search_title, :string, default: nil
      
      # modelling
      embed_one :eigenmodel
      one       :parent, model: :record
      one       :model, model: :model
      one       :child_model, model: :model
      records.descendants = [records]
      
      # security
      one   :view_group, model: :group
      one   :update_group, model: :group
      one   :delete_group, model: :group
      one   :create_group, model: :group
    end

    site.model_types['records'] = records.id
    site.model_plural_names['Record'] = 'records'
    site.save
  end
  
  def self.down(site)
    site.records.destroy
  end
end
