class Image < Attachment
  def set_file(file)
    super(file)
    crop_image
  end

  def crop_image
    sizes = @field.options['sizes'].to_hash.merge('admin_thumb' => '100x100')
    return unless exist?
    ImageScience.with_image(path.to_s) do |img|
      iw, ih = img.width, img.height
      sizes.each do |size_name, size|
        sw, sh = size.split('x').collect(&:to_i)
        aspect = sw.to_f / sh.to_f
        w, h = (ih * aspect), (iw / aspect)
        w = [iw, w].min.to_i
        h = [ih, h].min.to_i
        img.with_crop((iw-w)/2, (ih-h)/2, (iw+w)/2, (ih+h)/2) do |crop|
          crop.resize(sw, sh) do |resized|
            resized.save resized_image_path(size_name, false).to_s
          end
        end
      end
    end
  end

  # TODO: shouldn't always be .jpg; have image extension as an option
  def resized_image_path(size, crop_if_required=true)
    return path if size.nil? || size == :original
    sized_path = @record.site.attachments_directory.join(relative_directory_path, "#{size}.jpg")
    crop_image unless sized_path.exist? || !crop_if_required
    sized_path
  end

  # TODO: relative path from is quite a complex method; we should optimise the whole path system here somehow
  def relative_resized_image_path(name, crop_if_required=true)
    resized_image_path(name, crop_if_required).relative_path_from(@record.site.attachments_directory)
  end

  def url(size=:original, crop_if_required=true)
    if size == :original
      super()
    else
      Pathname.new('/').join(relative_resized_image_path(size, crop_if_required))
    end
  end
end
