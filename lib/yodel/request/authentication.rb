# some of the basic auth code taken from an inspired by rack/auth/basic
module Authentication
  AUTHORIZATION_KEYS = ['HTTP_AUTHORIZATION', 'X-HTTP_AUTHORIZATION', 'X_HTTP_AUTHORIZATION']
  
  def logged_in?(auth_type=nil)
    !current_user(auth_type).nil?
  end
  
  def current_user(auth_type=nil)
    unless defined?(@current_user)
      @current_user = nil
      auth_type ||= mime_type.auth_type
      case auth_type
      when :page
        if session['current_user_id']
          @current_user = site.users.find(session['current_user_id'])
          session.delete('current_user_id') if @current_user.nil?
        end
      when :basic
        unless authorization_key.nil? || !basic?
          user = site.users.first(username: credentials.first)
          @current_user = user if user.try(:passwords_match?, credentials.last)
        end
      end
    end
    @current_user
  end
  
  def prompt_login(auth_type=nil)
    auth_type ||= mime_type.auth_type
    case auth_type
    when :page
      session[:redirect_to_after_login] = self.path
      response.redirect site.login_pages.first.path
    when :basic
      response['Content-Type'] = 'text/plain'
      response['WWW-Authenticate'] = "Basic realm=\"#{title}\""
      response.status = 401
      response.body = []
    end
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
  
  private
    def authorization_key
      @authorization_key ||= AUTHORIZATION_KEYS.find {|key| env.has_key?(key)}
    end
    
    def basic?
      parts.first.downcase == 'basic'
    end
    
    def credentials
      @credentials ||= parts.last.unpack("m*").first.split(/:/, 2)
    end
    
    def parts
      @parts ||= env[authorization_key].split(' ', 2)
    end 
end
