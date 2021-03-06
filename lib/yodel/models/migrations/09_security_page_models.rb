class SecurityPageModelsMigration < Migration
  def self.up(site)
    site.pages.create_model :login_pages do |login_pages|
      add_field :username_field, :string, validations: {required: {}}, default: 'username'
      add_field :password_field, :string, validations: {required: {}}, default: 'password'
      add_one   :redirect_to, model: :page
      login_pages.record_class_name = 'LoginPage'
    end
    
    site.pages.create_model :logout_pages do |logout_pages|
      add_one :redirect_to, model: :page
      logout_pages.record_class_name = 'LogoutPage'
    end
    
    site.pages.create_model :password_reset_pages do |password_reset_pages|
      add_field :success, :html, default: 'Thank you, your password has been emailed to your email address.'
      add_field :email_field, :string, validations: {required: {}}, default: 'email'
      password_reset_pages.record_class_name = 'PasswordResetPage'
    end
    
    site.pages.create_model :facebook_login_pages do |facebook_login_pages|
      add_field :callback_uri, :string
      add_field :app_id, :string
      add_field :app_secret, :string
      add_one   :join_page, model: :page
      add_one   :after_login_page, model: :page
      facebook_login_pages.record_class_name = 'FacebookLoginPage'
    end
  end
  
  def self.down(site)
    site.login_pages.destroy
    site.logout_pages.destroy
    site.password_reset_pages.destroy
  end
end
