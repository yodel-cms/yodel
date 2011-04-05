module Yodel
  class MimeType
    attr_accessor :name, :extensions, :mime_types
    def initialize(name)
      @name = name
      @extensions = []
      @mime_types = []
      @processor = nil
      @builder = nil
      @layout_processor = :ember
    end

    def mime_types(*types)
      @mime_types += types
    end

    def extensions(*exts)
      @extensions += exts
    end

    def default_extension(ext=nil)
      @extensions.first
    end

    def default_mime_type
      @mime_types.first
    end

    def has_builder?
      !@builder.nil?
    end

    def builder(&block)
      @builder = block
    end

    def create_builder
      @builder ? @builder.call : nil
    end

    def has_processor?
      !@processor.nil?
    end

    def processor(&block)
      @processor = block
    end

    def process(data)
      @processor ? @processor.call(data) : data
    end
    
    def layout_processor(*processor)
      if processor.empty?
        @layout_processor
      else
        @layout_processor = processor.first
      end
    end
  end
end
