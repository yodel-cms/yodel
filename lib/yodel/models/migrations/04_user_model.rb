class UserModelMigration < Yodel::Migration
  def self.up(site)
    site.models.create_model 'User', inherits: 'Record' do |model|
      model.add_field :first_name, String, searchable: false
      model.add_field :last_name, String, searchable: false
      model.add_field :email, Email, required: true, unique: true, searchable: false
      model.add_field :username, String, required: true, index: true, unique: true, searchable: false
      model.add_field :password, Password, required: true, searchable: false
      model.add_field :password_salt, String, display: false, searchable: false
      
      model.add_field :name, Function, fn: '"#{first_name} #{last_name}".strip'
      model.icon = '/admin/images/user_icon.png'
      model.allowed_children = []
      model.allowed_parents = ['Group']
      model.klass = 'Yodel::User'
    end
  end
  
  def self.down(site)
    site.users.destroy
  end
end
