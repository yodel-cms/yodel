# TODO: look at cleaning up - @extensions and @mime_types don't appear to be used anywhere
module Yodel
  class MimeTypeSet
    attr_accessor :types
    def initialize
      @types = {}       # index by type name (:html)
      @extensions = {}  # index by type extensions (html, htm)
      @mime_types = {}  # index by mime types (text/html)
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
