module Yodel
  class MimeTypeSet
    attr_accessor :types
    def initialize
      @default = nil    # default mime type when no other can be matched
      @types = {}       # index by type name (:html)
      @extensions = {}  # index by type extensions (html, htm)
      @mime_types = {}  # index by mime types (text/html)
    end
    
    def each
      @types.values.each do |type|
        yield type
      end
    end
    
    def [](name)
      @types[name]
    end
    
    def <<(type)
      @default ||= type
      @types[type.name] = type
      type.extensions.each {|extension| @extensions[extension] = type}
      type.mime_types.each {|mime_type| @mime_types[mime_type] = type}
    end
    
    def mime_type_for_request(format, accept)
      # try to match by file extension first
      return @extensions[format] if format && @extensions.has_key?(format)
      
      # parse the accept string and try to match by mime type. The accept
      # header looks like: application/xml,text/html;q=0.9
      accept.to_s.split(',').each do |mime_type|
        name = mime_type.split(';').first
        return @mime_types[name] if @mime_types.has_key?(name)
      end
      
      # as a last resort, respond with the first mime type defined
      @default
    end
  end
end
