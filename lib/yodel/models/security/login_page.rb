module Yodel
  class LoginPage < Page
    respond_to :get do
      with :html do
        credentials = {username_field => params[username_field], password_field => params[password_field]}
        
        if login(credentials)
          path = session.delete(:redirect_to_after_login) || redirect_to.try(:path) || request.referrer || '/'
          response.redirect path
        else
          render
        end
      end
      
      with :json do
        credentials = {username_field => params[username_field], password_field => params[password_field]}
        {success: login(credentials)}
      end
    end
  end
end
