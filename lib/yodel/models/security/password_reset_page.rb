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
    
    respond_to :post do
      with :html do
        email = params[password_email_field]
        user = site.users.where(email: email)
        
        if user
          name = user.name
          new_password = user.reset_password
          site.emails[:password_reset].send_email to: user.email, new_password: new_password, name: user.name
          self.reset = true
        else
          self.failed_email_lookup = true
        end
        
        render
      end
      
      with :json do
        # FIXME: implement json page for this
      end
    end
  end
end
