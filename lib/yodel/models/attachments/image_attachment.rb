module Yodel
  class ImageAttachment < Attachment
    key :img_src, String
  
    def set_file(file)
      super(file)
      crop_image
    end
  
    def crop_image
      sizes = record.associations[attachment_name].options[:sizes]
      return if sizes.nil? || sizes.empty? || !exist?
      ImageScience.with_image(path.to_s) do |img|
        iw, ih = img.width, img.height
        sizes.each do |name, size|
          sw, sh = size.split('x').collect(&:to_i)
          aspect = sw.to_f / sh.to_f
          w, h = (ih * aspect), (iw / aspect)
          w = [iw, w].min.to_i
          h = [ih, h].min.to_i
          img.with_crop((iw-w)/2, (ih-h)/2, (iw+w)/2, (ih+h)/2) do |crop|
            crop.resize(sw, sh) do |resized|
              resized.save resized_image_path(name, false).to_s
            end
            if name == :admin_thumb
              self.img_src = self.resized_image_url(:admin_thumb, false)
              self.save
            end
          end
        end
      end
    end
  
    # TODO: shouldn't always be .jpg; have image extension as an option
    def resized_image_path(name, crop_if_required=true)
      path = Yodel.config.public_directory.join(relative_directory_path, "#{name}.jpg")
      crop_image unless path.exist? || !crop_if_required
      path
    end
  
    # TODO: relative path from is quite a complex method; we should optimise the whole path system here somehow
    def relative_resized_image_path(name, crop_if_required=true)
      resized_image_path(name, crop_if_required).relative_path_from(Yodel.config.public_directory)
    end
  
    def resized_image_url(name, crop_if_required=true)
       Pathname.new('/').join(relative_resized_image_path(name, crop_if_required))
    end
  
    def method_missing(name, *args)
      unless name.to_s.end_with?('_url')
        super(name, args)
      else
        resized_image_url(name.to_s.sub('_url', ''))
      end
    end
  end
end
