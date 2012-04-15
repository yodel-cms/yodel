class TestRecord < Test::Unit::TestCase
  context "An existing record" do
    setup do
      @record = $test_site.records.new
      @record.name = 'test'
      @record.save
    end
    
    should "not be new?" do
      assert !@record.new?
    end
    
    should "not be new? after reloading" do
      @record.reload
      assert !@record.new?
    end
    
    should "revert to saved values after reloading" do
      @record.name = 'test2'
      assert @record.name == 'test2'
      @record.reload
      assert assert @record.name == 'test'
    end
    
    should "successfuly destroy" do
      assert @record.destroy
    end
    
    should "not be new after being destroyed" do
      @record.destroy
      assert !@record.new?
    end
    
    should "be marked as destroyed after being destroyed" do
      @record.destroy
      assert @record.destroyed?
    end
    
    should "not be able to be destroyed after being destroyed already" do
      @record.destroy
      assert !@record.destroy
    end
  end
end
