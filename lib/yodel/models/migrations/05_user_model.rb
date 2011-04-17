class UserModelMigration < Yodel::Migration
  def self.up(site)
    site.records.create_model :users do |users|
      add_field :first_name, :string, searchable: false
      add_field :last_name, :string, searchable: false
      add_field :email, :email, validations: {required: {}, unique: {}}, searchable: false
      add_field :username, :string, index: true, validations: {required: {}, unique: {}}, searchable: false
      add_field :password, :password, validations: {required: {}}, searchable: false
      add_field :password_salt, :string, display: false, searchable: false
      add_many  :groups, default: [site.groups['Users'].id]
      add_field :owner, :self
      
      add_field :name, :function, fn: 'format("{{first_name}} {{last_name}}").strip()'
      users.icon = '/admin/images/user_icon.png'
      users.record_class_name = 'Yodel::User'
    end
  end
  
  def self.down(site)
    site.users.destroy
  end
end
