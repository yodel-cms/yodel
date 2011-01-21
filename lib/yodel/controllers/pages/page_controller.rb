module Yodel
  class PageController < Controller
    def self.handle_request(request, response, site, page)
      request.env['page'] = page
      super(request, response, site, :show)
    end
    
    def show
      page = env['page']
      html { page.layout.render_with_controller(self, {content: page.content}) }
      json { {content: page.content, title: page.title} }
    end
  end
end
