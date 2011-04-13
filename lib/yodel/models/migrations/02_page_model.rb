class PageModelMigration < Yodel::Migration
  def self.up(site)
    site.records.create_model :pages do |pages|
      # core page attributes
      add_field :permalink, :string, required: true, index: true, searchable: false, display: false
      add_field :path, :string, required: true, index: true, searchable: false, display: false
      add_field :created, :time, display: false
      add_field :title, :string, required: true
      add_field :content, :html
      
      # options section
      add_field :show_in_menus, :boolean, default: true, section: 'Options'
      add_field :description, :text, section: 'Options', searchable: false
      add_field :keywords, :text, section: 'Options', searchable: false
      add_field :custom_meta_tags, :text, section: 'Options', searchable: false
      one       :new_child_page, model: :page, section: 'Options'
      
      # layout
      add_field :page_layout, :string, section: 'Options', default: nil, searchable: false
      one       :page_layout_record, model: :layout, section: 'Options'
      
      #add_field :name, Function, fn: 'title'
      pages.default_child_model = pages.id
      pages.allowed_children = [pages]
      pages.allowed_parents = [pages]
      pages.record_class_name = 'Yodel::Page'
    end
  end
  
  def self.down(site)
    site.pages.destroy
  end
end
