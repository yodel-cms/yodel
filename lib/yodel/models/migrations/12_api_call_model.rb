class APICallModelMigration < Migration
  def self.up(site)
    site.records.create_model :api_calls do |api_calls|
      add_field :name, :string
      add_field :http_method, :string
      add_field :domain, :string
      add_field :port, :integer, default: 80
      add_field :path, :string
      add_field :username, :string
      add_field :password, :string
      add_field :authentication, :enum, options: %w{basic digest}
      add_field :mime_type, :string, default: 'json'
      add_field :body, :text
      add_field :body_layout, :string
      add_field :function, :string
      api_calls.record_class_name = 'APICall'
    end
  end
  
  def self.down(site)
    site.api_calls.destroy
  end
end
