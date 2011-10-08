class MenuModelMigration < Migration
  def self.up(site)
    site.records.create_model :menu do |menus|
      add_one   :root, model: :page, validations: {required: {}}
      add_field :include_root, :boolean, default: false
      add_field :include_all_children, :boolean, default: true
      add_field :depth, :integer, default: 0, validations: {required: {}}
      add_embed_many :exceptions do
        add_one   :page
        add_field :show, :boolean, default: false
        add_field :depth, :integer, default: 0, validations: {required: {}}
      end
      menus.record_class_name = 'Menu'
    end
  end
  
  def self.down(site)
    site.menus.destroy
  end
end
