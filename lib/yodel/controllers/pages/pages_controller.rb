module Yodel
  class PagesController < Controller
    def show
      page = Yodel::Page.where(path: params['glob'], site_id: site.id).first
      status(404) and return if page.nil? 
      page.page_controller.handle_request(@request, @response, @site, page)
    end
  end
end
