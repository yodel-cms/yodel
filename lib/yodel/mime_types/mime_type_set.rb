module Yodel
  class MimeTypeSet
    attr_accessor :types
    def initialize
      @types = {}
      @extensions = {}
      @mime_types = {}
    end
    
    def <<(type)
      @types[type.name] = type
      type.extensions.each {|extension| @extensions[extension] = type}
      type.mime_types.each {|mime_type| @mime_types[mime_type] = type}
    end
    
    def type(name)
      @types[name.to_sym]
    end
  end
end
