class FormMailerPageModelMigration < Migration
  def self.up(site)
    site.pages.create_model :form_mailer_page do |form_mailer_pages|
      add_many :emails, model: :email
      add_field :requirements, :array, of: :strings
      add_field :email_field, :string, default: 'email', validations: {required: {}}
      add_field :redirect_url, :string, searchable: false
      add_one   :redirect_page, model: :page, show_blank: true, blank_text: 'None'
      form_mailer_pages.record_class_name = 'FormMailerPage'
    end
  end
  
  def self.down(site)
    site.form_mailer_pages.destroy
  end
end
