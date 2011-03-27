class PageModelMigration < Yodel::Migration
  def self.up(site)
    site.models.create_model 'Page', inherits: 'Record' do |model|
      # core page attributes
      model.add_field :permalink, String, required: true, index: true, searchable: false, display: false
      model.add_field :path, String, required: true, index: true, searchable: false, display: false
      model.add_field :created, Time, display: false, eval: true, default: 'Time.now'
      model.add_field :title, String, required: true
      model.add_field :content, HTML
      
      # options section
      model.add_field :show_in_menus, Boolean, default: true, section: 'Options'
      model.add_field :description, Text, section: 'Options', searchable: false
      model.add_field :keywords, Text, section: 'Options', searchable: false
      model.add_field :custom_meta_tags, Text, section: 'Options', searchable: false
      model.add_field :new_child_page, Reference, to: 'Page', section: 'Options', default: nil
      
      # layout
      model.add_field :page_layout, String, section: 'Options', default: nil, searchable: false
      model.add_field :page_layout_record, Reference, to: 'Layout', section: 'Options', default: nil
      
      # override abstract record settings
      model.add_field :default_child_model, Reference, to: 'Model', default: 'site.pages.id', eval: true
      model.add_field :name, Function, fn: 'title'
      model.allowed_children = ['Page']
      model.allowed_parents = ['Page']
      model.klass = 'Yodel::Page'
    end
  end
  
  def self.down(site)
    site.pages.destroy
  end
end
