class PageEditLayoutMigration < Migration
  def self.up(site)
    site.pages.modify do |pages|
      add_field :edit_layout, :string, searchable: false, section: 'Options'
      add_one   :edit_layout_record, model: :layout, section: 'Options'
    end
  end
  
  def self.down(site)
    site.pages.modify do |pages|
      remove_field :edit_layout
      remove_field :edit_layout_record
    end
  end
end
