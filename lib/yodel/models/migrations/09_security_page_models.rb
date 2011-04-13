class SecurityPageModelsMigration < Yodel::Migration
  def self.up(site)
    site.pages.create_model :login_pages do |login_pages|
      add_field :username_field, :string, required: true, default: 'username'
      add_field :password_field, :string, required: true, default: 'password'
      one       :redirect_to, model: :page
      login_pages.record_class_name = 'Yodel::LoginPage'
    end
    
    site.pages.create_model :logout_pages do |logout_pages|
      one :redirect_to, model: :page
      logout_pages.record_class_name = 'Yodel::LogoutPage'
    end
    
    site.pages.create_model :password_reset_pages do |password_reset_pages|
      add_field :success, :html, default: 'Thank you, your password has been emailed to your email address.'
      add_field :email_field, :string, required: true, default: 'email'
      password_reset_pages.record_class_name = 'Yodel::PasswordResetPage'
    end
  end
  
  def self.down(site)
    site.login_pages.destroy
    site.logout_pages.destroy
    site.password_reset_pages.destroy
  end
end
