class LayoutModelMigration < Yodel::Migration
  def self.up(site)
    site.models.create_model 'Layout', inherits: 'Record' do |model|
      model.add_field :name, String, required: true, index: true, unique: true
      
      model.allowed_children = []
      model.allowed_parents = []
      model.searchable = false
      model.klass = 'Yodel::Layout'
    end
    
    site.models.create_model 'PersistentLayout', inherits: 'Layout' do |model|
      model.add_field :markup, HTMLCode, required: true
      model.add_field :pages, Many, of: 'Page', foreign_key: 'page_layout_record'
      
      model.allowed_children = ['PersistentLayout']
      model.allowed_parents = ['PersistentLayout']
      model.searchable = false
      model.klass = 'Yodel::PersistentLayout'
    end
    
    site.models.create_model 'FileLayout', inherits: 'Layout' do |model|
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
