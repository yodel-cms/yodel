class RecordProxyPageModelMigration < Migration
  def self.up(site)
    site.pages.create_model :record_proxy_pages do |record_proxy_pages|
      add_one   :record_model, model: :model
      add_one   :after_create_page, model: :page
      add_one   :after_delete_page, model: :page
      add_one   :after_update_page, model: :page
      add_field :show_record_layout, :string
      add_one   :show_record_layout_record, model: :layout, display: false
      record_proxy_pages.record_class_name = 'RecordProxyPage'
    end
  end
  
  def self.down(site)
    site.record_proxy_pages.destroy
  end
end
