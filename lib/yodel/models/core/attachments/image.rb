class Image < Attachment
  def set_file(file)
    super(file)
    crop_image
  end

  def crop_image
    sizes = (@field.options['sizes'] || {}).to_hash.merge('admin_thumb' => '100x100')
    return unless exist?
    
    # determine image dimensions
    dimensions = `#{Yodel.config.identify_path} -ping -format "%w %h" #{path}`
    unless ('0'..'9').include?(dimensions[0])
      raise "Invalid image format or unknown Image Magick error: #{dimensions}"
    else
      iw, ih = dimensions.split.map(&:to_i)
    end
    
    # resize to each custom size, using the given dimensions as a maximum and
    # minimum size - the resulting image is cropped if necessary
    sizes.each do |size_name, size|
      sw, sh = size.split('x').map(&:to_i)
      aspect = sw.to_f / sh.to_f
      w, h = (ih * aspect), (iw / aspect)
      w = [iw, w].min.to_i
      h = [ih, h].min.to_i
      
      command = "#{Yodel.config.convert_path} #{path} "
      command += "-crop '#{w}x#{h}+#{(iw-w)/2}+#{(ih-h)/2}' "
      command += "-resize '#{sw}x#{sh}' "
      command += "-quality #{Yodel.config.image_quality} "
      command += resized_image_path(size_name, false).to_s
      result = `#{command}`
      raise "Error converting image: #{result}" unless result.empty?
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
      Pathname.new('/').join(Yodel::ATTACHMENTS_DIRECTORY_NAME, relative_resized_image_path(size, crop_if_required))
    end
  end
end
