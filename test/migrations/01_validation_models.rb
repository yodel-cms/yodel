class ValidationModelsMigration < Migration
  def self.up(site)
    site.records.create_model :required_validation_test_model do |required_validation_test_model|
      add_field :name, :string, validations: {required: {}}
    end

    site.records.create_model :format_validation_test_model do |format_validation_test_model|
      add_field :formatted, :string, validations: {format: {format: /a\d+z/}}
    end

    site.records.create_model :email_address_validation_test_model do |email_address_validation_test_model|
      add_field :email, :email
    end

    site.records.create_model :min_length_validation_test_model do |min_length_validation_test_model|
      add_field :year, :string, validations: {length: {length: [4,0]}}
    end

    site.records.create_model :max_length_validation_test_model do |max_length_validation_test_model|
      add_field :age, :string, validations: {length: {length: [0,3]}}
    end

    site.records.create_model :length_range_validation_test_model do |length_range_validation_test_model|
      add_field :postcode, :string, validations: {length: {length: [3,4]}}
    end

    site.records.create_model :included_in_validation_test_model do |included_in_validation_test_model|
      add_field :gender, :string, validations: {included_in: {valid_values: %w{m f n/a}}}
    end

    site.records.create_model :excluded_from_validation_test_model do |excluded_from_validation_test_model|
      add_field :colour, :string, validations: {excluded_from: {prohibited_values: %w{red green blue}}}
    end

    site.records.create_model :includes_combinations_validation_test_model do |includes_combinations_validation_test_model|
      add_field :colours, :array, validations: {includes_combinations: {combinations: [%w{red green}, %w{green blue}]}}
    end

    site.records.create_model :excludes_combinations_validation_test_model do |excludes_combinations_validation_test_model|
      add_field :colours, :array, validations: {excludes_combinations: {combinations: [%w{red green}, %w{green blue}]}}
    end

    site.records.create_model :unique_validation_test_model do |unique_validation_test_model|
      add_field :name, :string, validations: {unique: {}}
    end
    
    site.records.create_model :multiple_validation_test_model do |multiple_validation_test_model|
      add_field :name, :string, validations: {required: {}, length: {length: [3,10]}, format: {format: /^[A-Z]/}}
    end
    
    site.records.create_model :embedded_records_validation_test_model do |embedded_records_validation_test_model|
      add_embed_many :items do
        add_field :name, :string, validations: {required: {}}
        add_field :season, :enum, options: %w{Summer Autumn Winter Spring},
                  set_validations: {
                    excludes_combinations: {combinations: [['Winter', 'Spring'], ['Winter', 'Summer']]}
                  }
      end
    end
  end
  
  def self.down(site)
  end
end
