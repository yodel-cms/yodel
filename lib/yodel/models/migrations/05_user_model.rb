class UserModelMigration < Yodel::Migration
  def self.up(site)
    site.records.create_model :users do |users|
      add_field :first_name, :string, searchable: false
      add_field :last_name, :string, searchable: false
      add_field :email, :email, required: true, unique: true, searchable: false
      add_field :username, :string, required: true, index: true, unique: true, searchable: false
      add_field :password, :password, required: true, searchable: false
      add_field :password_salt, :string, display: false, searchable: false
      many      :groups, default: [site.groups['Users'].id]
      
      #add_field :name, Function, fn: '"#{first_name} #{last_name}".strip'
      users.icon = '/admin/images/user_icon.png'
      users.record_class_name = 'Yodel::User'
    end
  end
  
  def self.down(site)
    site.users.destroy
  end
end
