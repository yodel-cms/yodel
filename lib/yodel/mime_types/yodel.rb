module Yodel  
  def self.mime_types(&block)
    if block_given?
      instance_eval &block
    else
      @mime_type_set ||= MimeTypeSet.new
    end
  end

  def self.mime_type(name, &block)
    mime_type = MimeType.new(name)
    mime_type.instance_eval &block
    mime_types << mime_type
  end
end

Yodel::DefaultMimeSet.load!
