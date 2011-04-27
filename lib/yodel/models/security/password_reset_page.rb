module Yodel
  class PasswordResetPage < Page
    def reset?
      !!@reset
    end
    
    def reset=(reset)
      @reset = reset
    end
    
    def failed_email_lookup?
      !!@failed_email_lookup
    end
    
    def failed_email_lookup=(failed)
      @failed_email_lookup = failed
    end
    
    respond_to :get do
      with :html do
        @email = params['email']
        render_or_default(:html) do
          "<p>Sorry, a layout couldn't be found for this page</p>" # FIXME: better error message
        end
      end
    end
    
    respond_to :post do
      with :html do
        email = params[email_field]
        user = site.users.where(email: email).first
        
        if user
          name = user.name
          new_password = user.reset_password
          site.emails[:password_reset].deliver_email to: user.email, new_password: new_password, name: user.name
          self.reset = true
        else
          self.failed_email_lookup = true
        end
        
        @email = email
        render_or_default(:html) do
          "<p>Sorry, a layout couldn't be found for this page</p>" # FIXME: better error message
        end
      end
      
      with :json do
        # FIXME: implement json page for this
      end
    end
  end
end
