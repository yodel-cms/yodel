require 'helper'

# ----------------------------------------------------------------------
# models used for each validation
# ----------------------------------------------------------------------
class RequiredValidationTestModel < MongoRecord
  field :name, :string, validations: {required: {}}
end

class FormatValidationTestModel < MongoRecord
  field :formatted, :string, validations: {format: {format: /a\d+z/}}
end

class EmailAddressValidationTestModel < MongoRecord
  field :email, :email
end

class MinLengthValidationTestModel < MongoRecord
  field :year, :string, validations: {length: {length: [4,0]}}
end

class MaxLengthValidationTestModel < MongoRecord
  field :age, :string, validations: {length: {length: [0,3]}}
end

class LengthRangeValidationTestModel < MongoRecord
  field :postcode, :string, validations: {length: {length: [3,4]}}
end

class IncludedInValidationTestModel < MongoRecord
  field :gender, :string, validations: {included_in: {valid_values: %w{m f n/a}}}
end

class ExcludedFromValidationTestModel < MongoRecord
  field :colour, :string, validations: {excluded_from: {prohibited_values: %w{red green blue}}}
end

class IncludesCombinationsValidationTestModel < MongoRecord
  field :colours, :array, validations: {includes_combinations: {combinations: [%w{red green}, %w{green blue}]}}
end

class ExcludesCombinationsValidationTestModel < MongoRecord
  field :colours, :array, validations: {excludes_combinations: {combinations: [%w{red green}, %w{green blue}]}}
end


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
      record = RequiredValidationTestModel.new
      assert !record.valid?
      assert record.errors.key?('name')
    end
    
    should "pass when a value is present" do
      record = RequiredValidationTestModel.new
      record.name = 'Name'
      assert record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # format
  # ----------------------------------------------------------------------
  context "Format validation" do
    should "fail when value is blank" do
      record = FormatValidationTestModel.new
      assert !record.valid?
      assert record.errors.key?('formatted')
    end
    
    should "fail when value format is incorrect" do
      record = FormatValidationTestModel.new
      record.formatted = 'b123z'
      assert !record.valid?
      assert record.errors.key?('formatted')
    end
    
    should "pass when value format is correct" do
      record = FormatValidationTestModel.new
      record.formatted = 'a123z'
      assert record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # email address
  # ----------------------------------------------------------------------
  context "Email address validation" do
    should "fail when value is blank" do
      record = EmailAddressValidationTestModel.new
      assert !record.valid?
      assert record.errors.key?('email')
    end
    
    should "fail when value is not an email address" do
      record = EmailAddressValidationTestModel.new
      record.email = 'hello'
      assert !record.valid?
      assert record.errors.key?('email')
    end
    
    should "pass when value is an email address" do
      record = EmailAddressValidationTestModel.new
      record.email = 'user@host.com'
      assert record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # length
  # ----------------------------------------------------------------------
  context "Max length validation" do
    should "fail when value length is too long" do
      record = MaxLengthValidationTestModel.new
      record.age = '9999'
      assert !record.valid?
      assert record.errors.key?('age')
      assert record.errors['age'].first.include?('too long')
    end
    
    should "pass when value length is less than the maximum length" do
      record = MaxLengthValidationTestModel.new
      record.age = '50'
      assert record.valid?
    end
  end
  
  context "Min length validation" do
    should "fail when value length is too short" do
      record = MinLengthValidationTestModel.new
      record.year = '200'
      assert !record.valid?
      assert record.errors.key?('year')
      assert record.errors['year'].first.include?('too short')
    end
    
    should "pass when value length is greater than the minimum length" do
      record = MinLengthValidationTestModel.new
      record.year = '2012'
      assert record.valid?
    end
  end
  
  context "Length range validation" do
    should "fail when value length is too short" do
      record = LengthRangeValidationTestModel.new
      record.postcode = '10'
      assert !record.valid?
      assert record.errors.key?('postcode')
      assert record.errors['postcode'].first.include?('must be between')
    end
    
    should "fail when value length is too long" do
      record = LengthRangeValidationTestModel.new
      record.postcode = '12345'
      assert !record.valid?
      assert record.errors.key?('postcode')
      assert record.errors['postcode'].first.include?('must be between')
    end
    
    should "pass when value length is within the length range" do
      record = LengthRangeValidationTestModel.new
      record.postcode = '2000'
      assert record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # included in
  # ----------------------------------------------------------------------
  context "Included in validation" do
    should "fail when value is not allowed" do
      record = IncludedInValidationTestModel.new
      record.gender = 'b'
      assert !record.valid?
      assert record.errors.key?('gender')
    end
    
    should "pass when value is allowed" do
      record = IncludedInValidationTestModel.new
      record.gender = 'n/a'
      assert record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # excluded from
  # ----------------------------------------------------------------------
  context "Excluded from validation" do
    should "fail when value is not allowed" do
      record = ExcludedFromValidationTestModel.new
      record.colour = 'red'
      assert !record.valid?
      assert record.errors.key?('colour')
    end
    
    should "pass when value is allowed" do
      record = ExcludedFromValidationTestModel.new
      record.colour = 'yellow'
      assert record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # includes combinations
  # ----------------------------------------------------------------------
  context "Includes combinations in validation" do
    should "fail when value is not allowed" do
      record = IncludesCombinationsValidationTestModel.new
      record.colours = %w{yellow purple}
      assert !record.valid?
      assert record.errors.key?('colours')
    end
    
    should "pass when value is allowed" do
      record = IncludesCombinationsValidationTestModel.new
      record.colours = %w{red green}
      assert record.valid?
    end
  end
  
  
  # ----------------------------------------------------------------------
  # excludes combinations
  # ----------------------------------------------------------------------
  context "Excludes combinations validation" do
    should "fail when value is not allowed" do
      record = ExcludesCombinationsValidationTestModel.new
      record.colours = %w{red green}
      assert !record.valid?
      assert record.errors.key?('colours')
    end
    
    should "pass when value is allowed" do
      record = ExcludesCombinationsValidationTestModel.new
      record.colours = %w{yellow purple}
      assert record.valid?
    end
  end
  
end
