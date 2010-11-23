module Yodel
  class Page < Yodel::Model
    allowed_descendants self
    single_root
    
    # core page attributes
    key :permalink, String, required: true, index: true
    key :path, String, required: true, index: true
    key :title, String, required: true
    key :content, ::HTML
    
    # behaviour tab
    #key :show_in_menus, Boolean, tab: 'Behaviour', default: true
    #key :show_in_search, Boolean, tab: 'Behaviour', default: true
    belongs_to :page_layout, class: Yodel::Layout, required: false#, tab: 'Behaviour'
    
    # SEO tab
    #key :description, Text, tab: 'SEO'
    #key :keywords, Text, tab: 'SEO'
    #key :custom_meta_tags, Text, tab: 'SEO', searchable: false
    
    
    # admin interface
    def self.icon
      '/admin/images/page_icon.png'
    end
    
    def name
      title
    end
    
    
    # searching
    searchable
    def show_in_search?
      show_in_search
    end
    

    # text content helpers
    def paragraph(index)
      paragraphs = Hpricot(content).search('/p')
      unless paragraphs.nil? || paragraphs[index].nil?
        paragraphs[index].inner_html
      else
        ''
      end
    end
    
    def paragraphs_from(index)
      paragraphs = Hpricot(content).search('/p')
      unless paragraphs.nil? || paragraphs[index..-1].nil?
        paragraphs[index..-1].collect {|p| p.to_s}.join('')
      else
        ''
      end
    end
    
    
    # permalinks are unique within the scope of the siblings of a page
    before_validation_on_create :assign_permalink
    def assign_permalink
      base_permalink = self.title.parameterize('_')
      suffix = ''
      count  = 0
      
      # ensure other pages don't have the same path as this page
      page_siblings = self.siblings
      while !page_siblings.select {|page| page.permalink == base_permalink + suffix}.empty?
        count += 1
        suffix = "_#{count}"
      end
      
      self.permalink = base_permalink + suffix
    end
    
    def path
      # the first ancestor is the root page (we ignore its permalink since it is accessed by '/')
      @path ||= '/' + parents.reverse[1..-1].collect(&:permalink).join('/')
    end
    
    
    # rendering
    def layout
      self.page_layout.nil? ? self.parent.layout : self.page_layout
    end
    
    def self.controller(*args)
      if args.size == 1
        @controller = args.first
      else
        @controller || Yodel::PageController
      end
    end
    
    def page_controller
      self.class.page_controller
    end
    
    def self.inherited(child)
      super(child)
      child.instance_variable_set('@controller', @controller)
    end
  end
end
