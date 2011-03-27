class EmailModelMigration < Yodel::Migration
  def self.up(site)
    site.models.create_model 'Email', inherits: 'Record' do |model|
      model.add_field :name, String
      model.add_field :from, String
      model.add_field :to, String
      model.add_field :cc, String
      model.add_field :bcc, String
      model.add_field :subject, String
      model.add_field :text_body, Text
      model.add_field :html_body, HTMLCode
      model.klass = 'Yodel::Email'
    end
    
    # template password reset email
    password_reset_email = site.emails.new
    password_reset_email.name = 'password_reset'
    password_reset_email.from = 'admin@site.com'
    password_reset_email.subject = 'Password Reset'
    password_reset_email.text_body = 'Hi #{user.name}, your password has been reset and is now: #{new_password}.'
    password_reset_email.save
  end
  
  def self.down(site)
    site.emails.destroy
  end
end
