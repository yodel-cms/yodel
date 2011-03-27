class GroupModelMigration < Yodel::Migration
  def self.up(site)
    site.models.create_model 'Group', inherits: 'Record' do |model|      
      model.add_field :name, String, required: true
      
      model.icon = '/admin/images/group_icon.png'
      model.allowed_children = ['Group', 'User']
      model.allowed_parents = ['Group']
    end
  end
  
  def self.down(site)
    site.groups.destroy
  end
end
