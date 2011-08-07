module Authentication
  def logged_in?
    !current_user.nil?
  end
  
  def current_user
    unless defined?(@current_user)
      if session['current_user_id']
        @current_user = site.users.find(session['current_user_id'])
        session.delete('current_user_id') if @current_user.nil?
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
      store_authenticated_user(user)
    end
    !@current_user.nil?
  end
  
  def logout
    session.delete('current_user_id')
  end
  
  def store_authenticated_user(user)
    session['current_user_id'] = user.id
    @current_user = user
  end
end
