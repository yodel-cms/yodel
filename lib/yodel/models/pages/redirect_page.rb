class RedirectPage < Page
  respond_to :get do
    with :html do
      if url?
        response.redirect url
      else
        response.redirect page.path
      end
    end
  end
end
