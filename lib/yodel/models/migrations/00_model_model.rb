# The model/record classes depend on a model structure existing, so
# the first model (of a model record) needs to be inserted manually.

class ModelModelMigration < Yodel::Migration
  def self.up(site)
    id = Yodel::Record::COLLECTION.insert({
      _model: 'Model',
      model_fields: [
        {
          name: 'model_fields',
          type: 'Array',
          default: []
        },
        {
          name: 'name',
          type: 'String',
        },
        {
          name: 'descendants',
          type: 'Array',
          default: []
        },
        {
          name: 'searchable',
          type: 'Boolean',
          default: true
        },
        {
          name: 'icon',
          type: 'String'
        },
        {
          name: 'allowed_children',
          type: 'Array',
          default: ['Record']
        },
        {
          name: 'allowed_parents',
          type: 'Array',
          default: ['Record']
        },
        {
          name: 'klass',
          type: 'String',
          default: 'Record'
        },
        {
          name: 'mixins',
          type: 'Array',
          default: []
        }
      ],
      name: 'Model',
      descendants: ['Model'],
      searchable: false,
      icon: nil,
      allowed_children: ['Model'],
      allowed_parents: ['Model'],
      klass: 'Model',
      mixins: [],
      _site_id: site.id,
      _parent_id: nil,
      _index: nil,
      _eigenmodel: []
    })

    site.model_plural_names['Model'] = 'models'
    site.model_types['models'] = id
    site.save
  end
  
  def self.down(site)
    site.models.destroy
  end
end
