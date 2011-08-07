class EmbeddedRecordArray < ChangeSensitiveArray
  def new(values={})
    EmbeddedRecord.new(@field, @record).tap {|record| record.update(values, false)}
  end
  
  private
    def notify!
      return if @notified
      @record.try(:changed!, @field.name)
      @notified = true
    end
end
