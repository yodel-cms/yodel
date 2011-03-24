class LayoutModelMigration < Yodel::Migration
  def self.up(site)
    site.models.create_model('Layout', site.records) do |model|
      model.add_field :name, String, required: true, index: true, unique: true
      
      model.allowed_children = []
      model.allowed_parents = []
      model.searchable = false
      model.klass = 'Yodel::Layout'
    end
    
    site.models.create_model('PersistentLayout', site.layouts) do |model|
      model.add_field :markup, HTMLCode, required: true
      
      model.allowed_children = ['PersistentLayout']
      model.allowed_parents = ['PersistentLayout']
      model.searchable = false
      model.klass = 'Yodel::PersistentLayout'
    end
    
    site.models.create_model('FileLayout', site.layouts) do |model|
      model.add_field :path, String, required: true
      
      model.allowed_children = ['FileLayout']
      model.allowed_parents = ['FileLayout']
      model.searchable = false
      model.klass = 'Yodel::FileLayout'
    end
  end
  
  def self.down(site)
    site.layouts.destroy
    site.persistent_layouts.destroy
    site.file_layouts.destroy
  end
end
