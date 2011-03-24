class SearchPageModelMigration < Yodel::Migration
  def self.up(site)
    site.models.create_model('SearchPage', site.pages) do |model|
      model.add_field :where, String, searchable: false
      model.add_field :sort, String, searchable: false
      model.add_field :limit, Integer
      model.add_field :skip, Integer
      model.add_field :type, Reference, to: 'Model', default: nil
      model.klass = 'Yodel::SearchPage'
    end
  end
  
  def self.down(site)
    site.snippets.destroy
  end
end
