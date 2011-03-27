class RecordProxyPageModelMigration < Yodel::Migration
  def self.up(site)
    site.models.create_model 'RecordProxyPage', inherits: 'Page' do |model|
      model.add_field :record_model, Reference, to: 'Model', default: nil
      model.add_field :after_create_page, Reference, to: 'Page', default: nil
      model.add_field :after_delete_page, Reference, to: 'Page', default: nil
      model.add_field :after_update_page, Reference, to: 'Page', default: nil
      model.add_field :new_record_page, Reference, to: 'Page', default: nil
      model.add_field :edit_record_page, Reference, to: 'Page', default: nil
      model.klass = 'Yodel::RecordProxyPage'
    end
  end
  
  def self.down(site)
    site.record_proxy_pages.destroy
  end
end
