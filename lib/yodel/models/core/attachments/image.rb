class Image < Attachment
  def set_file(file)
    super(file)
    crop_image
  end

  def crop_image
    sizes = (@field.options['sizes'] || {}).to_hash.merge('admin_thumb' => '100x100')
    return unless exist?    
    sizes.each do |size_name, size|
      image = MiniMagick::Image.open(path.to_s)
      image.resize("#{size}^")
      image.format('jpeg')
      image.write(resized_image_path(size_name, false).to_s)
    end
  end

  # TODO: shouldn't always be .jpg; have image extension as an option
  def resized_image_path(size, crop_if_required=true)
    return path if size.nil? || size == :original
    sized_path = File.join(@record.site.attachments_directory, relative_directory_path, "#{size}.jpg")
    crop_image unless File.exist?(sized_path) || !crop_if_required
    sized_path
  end

  # TODO: relative path from is quite a complex method; we should optimise the whole path system here somehow
  def relative_resized_image_path(name, crop_if_required=true)
    Pathname.new(resized_image_path(name, crop_if_required)).relative_path_from(Pathname.new(@record.site.attachments_directory))
  end

  def url(size=:original, crop_if_required=true)
    if size == :original
      super()
    else
      Pathname.new('/').join(relative_resized_image_path(size, crop_if_required))
    end
  end
end
