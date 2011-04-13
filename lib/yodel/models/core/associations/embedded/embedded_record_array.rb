module Yodel
  class EmbeddedRecordArray < Yodel::ChangeSensitiveArray
    def new
      Yodel::EmbeddedRecord.new(@field, @record)
    end
    
    private
      def notify!
        return if @notified
        @record.try(:changed!, @field.name)
        @notified = true
      end
  end
end
