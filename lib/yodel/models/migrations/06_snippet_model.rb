class SnippetModelMigration < Yodel::Migration
  def self.up(site)
    site.records.create_model :snippets do |snippets|
      add_field :name, :string, required: true, index: true
      add_field :content, :text
      snippets.searchable = false
    end
  end
  
  def self.down(site)
    site.snippets.destroy
  end
end
