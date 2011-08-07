class LoginPage < Page
  respond_to :post do
    with :html do
      credentials = {username_field => params[username_field], password_field => params[password_field]}
      
      if login(credentials)
        path = redirect_to.try(:path) || session.delete(:redirect_to_after_login) || request.referrer || '/'
        response.redirect path
      else
        flash.now(:login_failed, true)
        render_or_default(:html) do
          "<p>Sorry, your account could not be found</p>"
        end
      end
    end
    
    with :json do
      credentials = {username_field => params[username_field], password_field => params[password_field]}
      {success: login(credentials)}
    end
  end
end
