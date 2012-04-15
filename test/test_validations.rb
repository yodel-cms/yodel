# ----------------------------------------------------------------------
# models used for each validation
# ----------------------------------------------------------------------
class TestValidations < Test::Unit::TestCase
  context "Standard validations" do
    setup do
      @errors = ValidationErrors.new(AbstractRecord.new)
    end
    
    should "exist" do
      assert_respond_to @errors, :validate_email_address
      assert_respond_to @errors, :validate_embedded_records
      assert_respond_to @errors, :validate_excluded_from
      assert_respond_to @errors, :validate_excludes_combinations
      assert_respond_to @errors, :validate_format
      assert_respond_to @errors, :validate_included_in
      assert_respond_to @errors, :validate_includes_combinations
      assert_respond_to @errors, :validate_length
      assert_respond_to @errors, :validate_password_confirmation
      assert_respond_to @errors, :validate_required
      assert_respond_to @errors, :validate_unique
    end
  end
  
  
  # ----------------------------------------------------------------------
  # required
  # ----------------------------------------------------------------------
  context "Required validation" do
    should "fail when no value is present" do
      record = $test_site.required_validation_test_models.new
      assert !record.valid?
      assert record.errors.key?('name')
    end
    
    should "pass when a value is present" do
      record = $test_site.required_validation_test_models.new
      record.name = 'Name'
      assert record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # format
  # ----------------------------------------------------------------------
  context "Format validation" do
    should "fail when value is blank" do
      record = $test_site.format_validation_test_models.new
      assert !record.valid?
      assert record.errors.key?('formatted')
    end
    
    should "fail when value format is incorrect" do
      record = $test_site.format_validation_test_models.new
      record.formatted = 'b123z'
      assert !record.valid?
      assert record.errors.key?('formatted')
    end
    
    should "pass when value format is correct" do
      record = $test_site.format_validation_test_models.new
      record.formatted = 'a123z'
      assert record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # email address
  # ----------------------------------------------------------------------
  context "Email address validation" do
    should "fail when value is blank" do
      record = $test_site.email_address_validation_test_models.new
      assert !record.valid?
      assert record.errors.key?('email')
    end
    
    should "fail when value is not an email address" do
      record = $test_site.email_address_validation_test_models.new
      record.email = 'hello'
      assert !record.valid?
      assert record.errors.key?('email')
    end
    
    should "pass when value is an email address" do
      record = $test_site.email_address_validation_test_models.new
      record.email = 'user@host.com'
      assert record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # length
  # ----------------------------------------------------------------------
  context "Max length validation" do
    should "fail when value length is too long" do
      record = $test_site.max_length_validation_test_models.new
      record.age = '9999'
      assert !record.valid?
      assert record.errors.key?('age')
      assert record.errors['age'].first.include?('too long')
    end
    
    should "pass when value length is less than the maximum length" do
      record = $test_site.max_length_validation_test_models.new
      record.age = '50'
      assert record.valid?
    end
  end
  
  context "Min length validation" do
    should "fail when value length is too short" do
      record = $test_site.min_length_validation_test_models.new
      record.year = '200'
      assert !record.valid?
      assert record.errors.key?('year')
      assert record.errors['year'].first.include?('too short')
    end
    
    should "pass when value length is greater than the minimum length" do
      record = $test_site.min_length_validation_test_models.new
      record.year = '2012'
      assert record.valid?
    end
  end
  
  context "Length range validation" do
    should "fail when value length is too short" do
      record = $test_site.length_range_validation_test_models.new
      record.postcode = '10'
      assert !record.valid?
      assert record.errors.key?('postcode')
      assert record.errors['postcode'].first.include?('must be between')
    end
    
    should "fail when value length is too long" do
      record = $test_site.length_range_validation_test_models.new
      record.postcode = '12345'
      assert !record.valid?
      assert record.errors.key?('postcode')
      assert record.errors['postcode'].first.include?('must be between')
    end
    
    should "pass when value length is within the length range" do
      record = $test_site.length_range_validation_test_models.new
      record.postcode = '2000'
      assert record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # included in
  # ----------------------------------------------------------------------
  context "Included in validation" do
    should "fail when value is not allowed" do
      record = $test_site.included_in_validation_test_models.new
      record.gender = 'b'
      assert !record.valid?
      assert record.errors.key?('gender')
    end
    
    should "pass when value is allowed" do
      record = $test_site.included_in_validation_test_models.new
      record.gender = 'n/a'
      assert record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # excluded from
  # ----------------------------------------------------------------------
  context "Excluded from validation" do
    should "fail when value is not allowed" do
      record = $test_site.excluded_from_validation_test_models.new
      record.colour = 'red'
      assert !record.valid?
      assert record.errors.key?('colour')
    end
    
    should "pass when value is allowed" do
      record = $test_site.excluded_from_validation_test_models.new
      record.colour = 'yellow'
      assert record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # includes combinations
  # ----------------------------------------------------------------------
  context "Includes combinations in validation" do
    should "fail when value is not allowed" do
      record = $test_site.includes_combinations_validation_test_models.new
      record.colours = %w{yellow purple}
      assert !record.valid?
      assert record.errors.key?('colours')
    end
    
    should "pass when value is allowed" do
      record = $test_site.includes_combinations_validation_test_models.new
      record.colours = %w{red green}
      assert record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # excludes combinations
  # ----------------------------------------------------------------------
  context "Excludes combinations validation" do
    should "fail when value is not allowed" do
      record = $test_site.excludes_combinations_validation_test_models.new
      record.colours = %w{red green}
      assert !record.valid?
      assert record.errors.key?('colours')
    end
    
    should "pass when value is allowed" do
      record = $test_site.excludes_combinations_validation_test_models.new
      record.colours = %w{yellow purple}
      assert record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # unique
  # ----------------------------------------------------------------------
  context "Unique validation" do
    setup do
      name_a = $test_site.unique_validation_test_models.new
      name_a.name = 'Bob'
      name_a.save
    end
    
    should "fail when value is not unique" do
      name_b = $test_site.unique_validation_test_models.new
      name_b.name = 'Bob'
      assert !name_b.valid?
      assert name_b.errors.key?('name')
    end
    
    should "pass when value is unique" do
      name_b = $test_site.unique_validation_test_models.new
      name_b.name = 'Smith'
      assert name_b.valid?
    end
  end
  
end
