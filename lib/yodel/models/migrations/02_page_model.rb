class PageModelMigration < Migration
  def self.up(site)
    site.records.create_model :pages do |pages|
      # core page attributes
      add_field :permalink, :string, validations: {required: {}}, index: true, searchable: false, display: false
      add_field :path, :string, validations: {required: {}}, index: true, searchable: false, display: false
      add_field :created_at, :time, display: false
      add_field :title, :string, validations: {required: {}}
      add_field :content, :html
      
      # options section
      add_field :show_in_menus, :boolean, default: true, section: 'Options'
      add_field :description, :text, section: 'Options', searchable: false
      add_field :keywords, :text, section: 'Options', searchable: false
      add_field :custom_meta_tags, :text, section: 'Options', searchable: false
      add_one   :new_child_page, model: :page, section: 'Options', show_blank: true, blank_text: 'None'
      
      # layout
      add_field :page_layout, :string, section: 'Options', default: nil, searchable: false
      add_one   :page_layout_record, model: :layout, display: false
      add_field :edit_layout, :string, searchable: false, section: 'Options'
      add_one   :edit_layout_record, model: :layout, display: false
      
      add_field :name, :alias, of: :title
      pages.default_child_model = pages.id
      pages.allowed_children = [pages]
      pages.allowed_parents = [pages]
      pages.record_class_name = 'Page'
    end
    
    # glob pages are normal pages, but match paths with components at the end
    # of the page's path, e.g /git/HEAD would match the glob page /git
    site.pages.create_model :glob_pages do |glob_pages|
    end
    
    # default root page
    page = site.pages.new
    page.title = "Home"
    page.save
  end
  
  def self.down(site)
    site.pages.destroy
  end
end
