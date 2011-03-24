module Yodel
  module Authentication
    def logged_in?
      !current_user.nil?
    end
    
    def current_user
      unless defined?(@current_user)
        if session['current_user_id']
          @current_user = site.users.first(_id: session['current_user_id'])
        else
          @current_user = nil
        end
      end
      @current_user
    end
    
    def login(credentials)
      password = credentials.delete('password')
      user = site.users.first(credentials)
      if user && user.passwords_match?(password)
        session['current_user_id'] = user._id
      end
      !user.nil?
    end
    
    def logout
      session.delete('current_user_id')
    end
  end
end
