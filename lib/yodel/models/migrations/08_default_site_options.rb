class DefaultSiteOptionsMigration < Yodel::Migration
  def self.up(site)
    site.options = {
      pages: {
        options: {
          permalink_character: {
            description: 'When Yodel creates a URL for a page by using the title of the page, there are sometimes characters (such as spaces) that need to be replaced. This character will be used in their place. e.g "About Us" would become "about-us".',
            type: 'String',
            default: '-',
            value: '-'
          }
        },
        icon: nil,
        order: ['permalink_character']
      },
      order: ['pages']
    }
    site.save
  end
  
  def self.down(site)
    site.options = {}
    site.save
  end
end
