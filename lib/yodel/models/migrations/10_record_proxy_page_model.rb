class RecordProxyPageModelMigration < Yodel::Migration
  def self.up(site)
    site.pages.create_model :record_proxy_pages do |record_proxy_pages|
      add_one :record_model, model: :model
      add_one :after_create_page, model: :page
      add_one :after_delete_page, model: :page
      add_one :after_update_page, model: :age
      add_one :new_record_page, model: :page
      add_one :edit_record_page, model: :age
      record_proxy_pages.record_class_name = 'Yodel::RecordProxyPage'
    end
  end
  
  def self.down(site)
    site.record_proxy_pages.destroy
  end
end
