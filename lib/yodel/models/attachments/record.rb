module Yodel
  class Record
    def self.attachment(name)
      class_eval "has_one :#{name}, class: Yodel::Attachment, dependent: :destroy, display: true"
      define_attachment_setter(name)
    end
    
    def self.unique_attachment(name)
      class_eval "has_one :#{name}, class: Yodel::UniqueAttachment, dependent: :destroy, display: true"
      define_attachment_setter(name)
    end
    
    def self.image(name, sizes={})
      class_eval "has_one :#{name}, class: Yodel::ImageAttachment, dependent: :destroy, display: true, sizes: #{{admin_thumb:"100x100"}.merge(sizes).inspect}"
      define_attachment_setter(name)
    end
    
    private
      def self.define_attachment_setter(name)
        class_eval "
          def #{name}=(file)
            return if file.nil?
            if file[:tempfile]
              #{name}.build(attachment_name: '#{name}') if #{name}.nil?
              #{name}.set_file(file)
            else
              #{name}.replace(file)
            end
          end
        "
      end
  end
end
