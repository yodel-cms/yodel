class RedirectPage < Page
  respond_to :get do
    with :html do
      if url?
        response.redirect url
      elsif page?
        response.redirect page.path
      else
        response.redirect '/'
      end
    end
  end
end
