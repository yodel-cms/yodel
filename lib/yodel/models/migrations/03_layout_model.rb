class LayoutModelMigration < Yodel::Migration
  def self.up(site)
    site.records.create_model :layouts do |layouts|
      add_field :name, :string, required: true, index: true
      add_field :mime_type, :string, required: true, index: true
      
      layouts.allowed_children = []
      layouts.allowed_parents = []
      layouts.searchable = false
      layouts.record_class_name = 'Yodel::Layout'
    end
    
    site.layouts.create_model :persistent_layouts do |persistent_layouts|
      add_field :markup, :html, required: true
      many      :pages, store: false, foreign_key: 'page_layout_record'
      
      persistent_layouts.allowed_children = [persistent_layouts]
      persistent_layouts.allowed_parents = [persistent_layouts]
      persistent_layouts.searchable = false
      persistent_layouts.record_class_name = 'Yodel::PersistentLayout'
    end
    
    site.layouts.create_model :file_layouts do |file_layouts|
      add_field :path, :string, required: true
      
      file_layouts.allowed_children = [file_layouts]
      file_layouts.allowed_parents = [file_layouts]
      file_layouts.searchable = false
      file_layouts.record_class_name = 'Yodel::FileLayout'
    end
  end
  
  def self.down(site)
    site.layouts.destroy
    site.persistent_layouts.destroy
    site.file_layouts.destroy
  end
end
