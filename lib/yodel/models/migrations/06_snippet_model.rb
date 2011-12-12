class SnippetModelMigration < Migration
  def self.up(site)
    site.records.create_model :snippets do |snippets|
      add_field :name, :string, validations: {required: {}}, index: true
      add_field :show_in_search, :boolean, default: false, display: false
      add_field :content, :text
      snippets.searchable = false
    end
  end
  
  def self.down(site)
    site.snippets.destroy
  end
end
