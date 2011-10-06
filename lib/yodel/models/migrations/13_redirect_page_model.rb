class RedirectPageModelMigration < Migration
  def self.up(site)
    site.pages.create_model :redirect_page do |redirect_pages|
      add_field :url, :string, searchable: false
      add_one   :page, show_blank: true, blank_text: 'None'
      redirect_pages.record_class_name = 'RedirectPage'
    end
  end
  
  def self.down(site)
    site.redirect_pages.destroy
  end
end
