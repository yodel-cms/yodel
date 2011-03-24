class SnippetModelMigration < Yodel::Migration
  def self.up(site)
    site.models.create_model('Snippet') do |model|
      model.add_field :name, String, required: true, index: true
      model.add_field :content, Text
      model.searchable = false
    end
  end
  
  def self.down(site)
    site.snippets.destroy
  end
end
