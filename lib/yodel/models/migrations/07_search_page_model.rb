class SearchPageModelMigration < Yodel::Migration
  def self.up(site)
    site.models.create_model 'SearchPage', inherits: 'Page' do |model|
      model.add_field :conditions, Embedded, fields: [
        {
          name: :field,
          type: String
        },
        {
          name: :value,
          type: String
        },
        {
          name: :operator,
          type: Enum,
          values: ['Equals', 'Not Equal', 'Greater Than', 'Less Than', 'Greater Than or Equal To', 'Less Than or Equal To', 'In']
        }
      ]
      model.add_field :sort, String, searchable: false
      model.add_field :limit, Integer
      model.add_field :skip, Integer
      model.add_field :type, Reference, to: 'Model', default: nil
      model.add_field :user_conditions, Embedded, fields: [
        {
          name: :field,
          type: String
        },
        {
          name: :as,
          type: String
        },
        {
          name: :operator,
          type: Enum,
          values: ['Equals', 'Not Equal', 'Greater Than', 'Less Than', 'Greater Than or Equal To', 'Less Than or Equal To', 'In']
        }
      ], default: [{field: 'search_keywords', as: 'query', operator: 'In'}]
      model.add_field :json_fields, Array, default: ['id', 'name']
      model.klass = 'Yodel::SearchPage'
    end
  end
  
  def self.down(site)
    site.search_pages.destroy
  end
end
