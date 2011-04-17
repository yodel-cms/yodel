class SearchPageModelMigration < Yodel::Migration
  def self.up(site)
    operators = [ 'Equals', 'Not Equal', 'Greater Than',
                  'Less Than', 'Greater Than or Equal To',
                  'Less Than or Equal To', 'In']
                  
    site.pages.create_model :search_pages do |search_pages|
      add_field :sort, :string, searchable: false
      add_field :limit, :integer
      add_field :skip, :integer
      add_one   :type, model: :model
      
      add_embed_many :conditions do
        add_field :name, :string
        add_field :value, :string
        add_field :operator, :enum, options: operators
      end
      
      add_embed_many :user_conditions, default: [{name: 'search_keywords', as: 'query', operator: 'In'}] do
        add_field :name, :string
        add_field :as, :string
        add_field :operator, :enum, options: operators
      end
      
      search_pages.record_class_name = 'Yodel::SearchPage'
    end
  end
  
  def self.down(site)
    site.search_pages.destroy
  end
end
