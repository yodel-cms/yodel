class ImageQualityAsSiteOptionMigration < Migration
  def self.up(site)
    site.options[:images] = {
      image_quality: {
        description: 'The JPEG quality setting Yodel will use when resizing images. This is a number between 0 and 100, where 100 will result in images of the highest possible quality, and correspondingly large file sizes.',
        type: 'Integer',
        default: '95',
        value: '95'
      }
    }
    site.save
  end
  
  def self.down(site)
    site.options.delete('images')
    site.save
  end
end
