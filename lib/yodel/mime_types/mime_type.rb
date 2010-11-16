module Yodel
  class MimeType
    attr_accessor :name, :extensions, :mime_types
    def initialize(name)
      @name = name
      @extensions = []
      @mime_types = []
      @transformer = nil
    end

    def mime_types(*types)
      @mime_types += types
    end

    def extensions(*exts)
      @extensions += exts
    end

    def default_extension(ext=nil)
      if ext.nil?
        @extensions[0]
      else
        @extensions.delete(ext)
        @extensions.insert(0, ext)
      end
    end

    def default_mime_type(type=nil)
      if type.nil?
        @mime_types[0]
      else
        @mime_types.delete(type)
        @mime_types.insert(0, type)
      end      
    end

    def default_extension=(ext)
      default_extension(ext)
    end

    def default_mime_type=(type)
      default_mime_type(type)
    end

    def builder(&block)
      @builder = block
    end

    def create_builder
      if @builder
        @builder.call
      else
        nil
      end
    end

    def transformer(&block)
      @transformer = block
    end

    def process(data)
      if @transformer
        @transformer.call(data)
      else
        data
      end
    end

    def matches_request?(request)
      # try format first, then fall back to accept header
      if request.params['format']
        @extensions.include?(request.params['format'])
      else
        @mime_types.each do |type|
          return true if request.env['HTTP_ACCEPT'].include?(type)
        end
        false
      end
    end
  end
end
