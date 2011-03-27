class SecurityPageModelsMigration < Yodel::Migration
  def self.up(site)
    site.models.create_model 'LoginPage', inherits: 'Page' do |model|
      model.add_field :username_field, String, required: true, default: 'username'
      model.add_field :password_field, String, required: true, default: 'password'
      model.add_field :redirect_to, Reference, to: 'Page', default: nil
      model.klass = 'Yodel::LoginPage'
    end
    
    site.models.create_model 'LogoutPage', inherits: 'Page' do |model|
      model.add_field :redirect_to, Reference, to: 'Page', default: nil
      model.klass = 'Yodel::LogoutPage'
    end
    
    site.models.create_model 'PasswordResetPage', inherits: 'Page' do |model|
      model.add_field :success, HTML, default: 'Thank you, your password has been emailed to your email address.'
      model.add_field :email_field, String, required: true, default: 'email'
      model.klass = 'Yodel::PasswordResetPage'
    end
  end
  
  def self.down(site)
    site.login_pages.destroy
    site.logout_pages.destroy
    site.password_reset_pages.destroy
  end
end
