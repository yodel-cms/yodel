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
    setup do
      @record = $test_site.required_validation_test_models.new
    end
    
    should "fail when no value is present" do
      assert !@record.valid?
      assert @record.errors.key?('name')
    end
    
    should "pass when a value is present" do
      @record.name = 'Name'
      assert @record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # format
  # ----------------------------------------------------------------------
  context "Format validation" do
    setup do
      @record = $test_site.format_validation_test_models.new
    end
    
    should "fail when value is blank" do
      assert !@record.valid?
      assert @record.errors.key?('formatted')
    end
    
    should "fail when value format is incorrect" do
      @record.formatted = 'b123z'
      assert !@record.valid?
      assert @record.errors.key?('formatted')
    end
    
    should "pass when value format is correct" do
      @record.formatted = 'a123z'
      assert @record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # email address
  # ----------------------------------------------------------------------
  context "Email address validation" do
    setup do
      @record = $test_site.email_address_validation_test_models.new
    end
    
    should "fail when value is blank" do
      assert !@record.valid?
      assert @record.errors.key?('email')
    end
    
    should "fail when value is not an email address" do
      @record.email = 'hello'
      assert !@record.valid?
      assert @record.errors.key?('email')
    end
    
    should "pass when value is an email address" do
      @record.email = 'user@host.com'
      assert @record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # length
  # ----------------------------------------------------------------------
  context "Max length validation" do
    setup do
      @record = $test_site.max_length_validation_test_models.new
    end
    
    should "fail when value length is too long" do
      @record.age = '9999'
      assert !@record.valid?
      assert @record.errors.key?('age')
      assert @record.errors['age'].first.include?('too long')
    end
    
    should "pass when value length is less than the maximum length" do
      @record.age = '50'
      assert @record.valid?
    end
  end
  
  context "Min length validation" do
    setup do
      @record = $test_site.min_length_validation_test_models.new
    end
    
    should "fail when value length is too short" do
      @record.year = '200'
      assert !@record.valid?
      assert @record.errors.key?('year')
      assert @record.errors['year'].first.include?('too short')
    end
    
    should "pass when value length is greater than the minimum length" do
      @record.year = '2012'
      assert @record.valid?
    end
  end
  
  context "Length range validation" do
    setup do
      @record = $test_site.length_range_validation_test_models.new
    end
    
    should "fail when value length is too short" do
      @record.postcode = '10'
      assert !@record.valid?
      assert @record.errors.key?('postcode')
      assert @record.errors['postcode'].first.include?('must be between')
    end
    
    should "fail when value length is too long" do
      @record.postcode = '12345'
      assert !@record.valid?
      assert @record.errors.key?('postcode')
      assert @record.errors['postcode'].first.include?('must be between')
    end
    
    should "pass when value length is within the length range" do
      @record.postcode = '2000'
      assert @record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # included in
  # ----------------------------------------------------------------------
  context "Included in validation" do
    setup do
      @record = $test_site.included_in_validation_test_models.new
    end
    
    should "fail when value is not allowed" do
      @record.gender = 'b'
      assert !@record.valid?
      assert @record.errors.key?('gender')
    end
    
    should "pass when value is allowed" do
      @record.gender = 'n/a'
      assert @record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # excluded from
  # ----------------------------------------------------------------------
  context "Excluded from validation" do
    setup do
      @record = $test_site.excluded_from_validation_test_models.new
    end
    
    should "fail when value is not allowed" do
      @record.colour = 'red'
      assert !@record.valid?
      assert @record.errors.key?('colour')
    end
    
    should "pass when value is allowed" do
      @record.colour = 'yellow'
      assert @record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # includes combinations
  # ----------------------------------------------------------------------
  context "Includes combinations in validation" do
    setup do
      @record = $test_site.includes_combinations_validation_test_models.new
    end
    
    should "fail when value is not allowed" do
      @record.colours = %w{yellow purple}
      assert !@record.valid?
      assert @record.errors.key?('colours')
    end
    
    should "pass when value is allowed" do
      @record.colours = %w{red green}
      assert @record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # excludes combinations
  # ----------------------------------------------------------------------
  context "Excludes combinations validation" do
    setup do
      @record = $test_site.excludes_combinations_validation_test_models.new
    end
    
    should "fail when value is not allowed" do
      @record.colours = %w{red green}
      assert !@record.valid?
      assert @record.errors.key?('colours')
    end
    
    should "pass when value is allowed" do
      @record.colours = %w{yellow purple}
      assert @record.valid?
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
  
  
  # ----------------------------------------------------------------------
  # password confirmation
  # ----------------------------------------------------------------------
  context "Password confirmation validation" do
    setup do
      @user = $test_site.users.new
      @user.email = "user@test.com"
      @user.username = "abc"
    end
    
    teardown do
      @user.destroy
    end
    
    context "when no password has been saved" do
      setup do
        @user.save_without_validation
      end
      
      should "pass when no confirmation is provided" do
        @user.from_json({'first_name' => 'fred'}, false)
        assert @user.valid?
        @user.reload
        
        @user.from_json({'password' => '123'}, false)
        assert @user.valid?
      end
      
      should "pass when a confirmation is provided" do
        @user.from_json({'first_name' => 'fred', 'current_password' => '123'}, false)
        assert @user.valid?
        @user.reload
        
        @user.from_json({'password' => '123', 'current_password' => 'xyz'}, false)
        assert @user.valid?
      end
    end
    
    context "when a password has been saved" do
      setup do
        @user.password = "123"
        @user.save
      end
      
      should "pass when the password field is not being updated" do
        @user.from_json({'first_name' => 'fred'}, false)
        assert @user.valid?
      end
      
      should "fail when the password field is updated and no confirmation is provided" do
        @user.from_json({'password' => 'abc'}, false)
        assert !@user.valid?
        assert @user.errors.key?('password')
      end
      
      should "fail when the password field is updated and the confirmation doesn't match the existing password" do
        @user.from_json({'password' => 'abc', 'current_password' => 'abc'}, false)
        assert !@user.valid?
        assert @user.errors.key?('password')
      end
      
      should "pass when the password field is updated and the confirmation matches the existing password" do
        @user.from_json({'password' => 'abc', 'current_password' => '123'}, false)
        assert @user.valid?
      end
    end
  end
  
end
