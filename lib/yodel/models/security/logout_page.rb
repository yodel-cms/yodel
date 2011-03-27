module Yodel
  class LogoutPage < Page
    respond_to :get do
      with :html do
        logout
        response.redirect redirect_to.try(:path) || '/'
      end
      
      with :json do
        logout
        {success: true}
      end
    end
  end
end
