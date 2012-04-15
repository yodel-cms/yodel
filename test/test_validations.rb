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
  
  # ----------------------------------------------------------------------
  # embedded record validations
  # ----------------------------------------------------------------------
  context "Embedded record validations" do
    setup do
      @record = $test_site.embedded_records_validation_test_models.new
      @record.items.new({'name' => 'item1', 'season' => 'Summer'}).save
    end
    
    should "fail when an embedded validation fails" do
      new_item = @record.items.new
      @record.items << new_item
      assert !@record.valid?
      assert @record.errors.all_record_errors_to_hash.key?(new_item.id.to_s)
    end
    
    should "pass when all embedded validations pass" do
      # the initial item in @record is valid
      assert @record.valid?
      
      # test a second item is valid too
      @record.items.new({'name' => 'item2'}).save
      assert @record.valid?
    end
    
    should "fail when set validations fail" do
      @record.items.new({'name' => 'item2', 'season' => 'Winter'}).save
      assert !@record.valid?
      assert @record.errors.key?('items')
    end
    
    should "pass when set validations pass" do
      @record.items.new({'name' => 'item2', 'season' => 'Spring'}).save
      assert @record.valid?
    end
  end

  
  # ----------------------------------------------------------------------
  # multiple validations
  # ----------------------------------------------------------------------
  context "A field with multiple validations" do
    setup do
      @record = $test_site.multiple_validation_test_models.new
    end
    
    should "be invalid if its validations don't pass" do
      assert !@record.valid?
      assert @record.errors.key?('name')
      
      # satisfy required, but not length or format
      @record.name = 'a'
      assert !@record.valid?
      assert @record.errors.key?('name')
      
      # satisfy required and length, but not format
      @record.name = 'abc'
      assert !@record.valid?
      assert @record.errors.key?('name')
      
      # satisfy required and format, but not length
      @record.name = 'Ab'
      assert !@record.valid?
      assert @record.errors.key?('name')
      
      # satisfy all three validations
      @record.name = 'Abc'
      assert @record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # validations only on modified values
  # ----------------------------------------------------------------------
  context "Validations" do
    setup do
      @user = $test_site.users.new
      @user.email = "user@test.com"
      @user.username = "abc"
      @user.password = "123"
      @user.save
    end
    
    teardown do
      @user.destroy
    end
    
    should "only be applied to modified values" do
      # the original user is valid
      assert @user.valid?
      
      # invalidate a field
      @user.username = ''
      assert !@user.valid?
      assert @user.errors.key?('username')
      
      # ensure the reloaded original value returns the record to valid
      @user.reload
      assert @user.valid?
    end
    
    should "only be applied to modified values, ignoring previously saved invalid values" do
      # force a field to become invalid
      @user.username = ''
      @user.save_without_validation
      assert @user.valid?
      
      # invalidate another, only it should be invalid
      @user.email = ''
      assert !@user.valid?
      assert @user.errors.to_hash.keys.length == 1
      assert @user.errors.key?('email')
    end
    
    should "pass on previously saved invalid values after reloading" do
      # create a record with an invalid field
      @record = $test_site.multiple_validation_test_models.new
      @record.name = 'a'
      @record.save_without_validation
      assert @record.valid?
      
      # update the field with a new invalid value
      @record.name = 'b'
      assert !@record.valid?
      assert @record.errors.key?('name')
      
      # test the reloaded record is valid
      @record.reload
      assert @record.valid?
      
      @record.destroy
    end
  end
  
  
  # ----------------------------------------------------------------------
  # validations on multiple fields
  # ----------------------------------------------------------------------
  context "A record with validations on multiple fields" do
    setup do
      @user = $test_site.users.new
    end
    
    should "be invalid if any of its fields are invalid" do
      assert !@user.valid?
      assert @user.errors.to_hash.keys.length == 3
      assert @user.errors.key?('username')
      assert @user.errors.key?('password')
      assert @user.errors.key?('email')
      
      @user.email = "user@test.com"
      assert !@user.valid?
      assert @user.errors.to_hash.keys.length == 2
      assert @user.errors.key?('username')
      assert @user.errors.key?('password')
      
      @user.email = nil
      @user.username = "abc"
      assert !@user.valid?
      assert @user.errors.to_hash.keys.length == 2
      assert @user.errors.key?('password')
      assert @user.errors.key?('email')
      
      @user.username = nil
      @user.password = "123"
      assert !@user.valid?
      assert @user.errors.to_hash.keys.length == 2
      assert @user.errors.key?('username')
      assert @user.errors.key?('email')
    end
    
    should "be valid if all of its fields are valid" do
      @user.email = "user@test.com"
      @user.username = "abc"
      @user.password = "123"
      assert @user.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # json output
  # ----------------------------------------------------------------------
  context "The JSON output of a record's errors" do
    setup do
      @record = $test_site.embedded_records_validation_test_models.new
      @item_1 = @record.items.new({season: 'Winter'})
      @record.items << @item_1
      @item_2 = @record.items.new({season: 'Summer'})
      @record.items << @item_2
      @record.valid?
      @json_hash = @record.errors.all_record_errors_to_hash
    end
    
    should "nest the record's errors under the id of the record" do
      assert @json_hash.key?(@record.id.to_s)
      assert @json_hash[@record.id.to_s].key?('items')
    end
    
    should "nest embedded record errors under their own ids" do
      assert @json_hash.key?(@item_1.id.to_s)
      assert @json_hash.key?(@item_2.id.to_s)
      assert @json_hash[@item_1.id.to_s].key?('name')
      assert @json_hash[@item_2.id.to_s].key?('name')
    end
    
    should "store validations errors in an array" do
      assert @json_hash[@record.id.to_s]['items'].is_a?(Array)
      assert @json_hash[@item_1.id.to_s]['name'].is_a?(Array)
      assert @json_hash[@item_2.id.to_s]['name'].is_a?(Array)
    end
  end
end
