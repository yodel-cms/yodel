class EmailModelMigration < Yodel::Migration
  def self.up(site)
    site.records.create_model :emails do |emails|
      add_field :name, :string
      add_field :from, :string
      add_field :to, :string
      add_field :cc, :string
      add_field :bcc, :string
      add_field :subject, :string
      add_field :text_body, :text
      add_field :html_body, :html
      emails.record_class_name = 'Yodel::Email'
    end
    
    # template password reset email
    password_reset_email = site.emails.new
    password_reset_email.name = 'password_reset'
    password_reset_email.from = 'admin@site.com'
    password_reset_email.subject = 'Password Reset'
    password_reset_email.text_body = 'Hi <%= name %>, your password has been reset and is now: <%= new_password %>.'
    password_reset_email.save
  end
  
  def self.down(site)
    site.emails.destroy
  end
end
