class FacebookLoginPage < Page
  GRAPH_DOMAIN  = 'graph.facebook.com'
  ACCESS_URL    = "/oauth/access_token?"
  USER_URL      = "/me?"
  
  respond_to :get do
    with :html do
      begin
        if params['code']
          auth_code = params['code']
          access_url = ACCESS_URL
          access_url += "client_id=#{app_id}"
          access_url += "&redirect_uri=#{callback_uri}"
          access_url += "&client_secret=#{app_secret}"
          access_url += "&code=#{auth_code}"
          access_code = get_https(access_url)
        
          # read user details
          if access_code
            user_response = get_https("#{USER_URL}#{access_code}")
            user_details = JSON.parse(user_response)
            if user_details['id']
              user = site.users.where(oauth_id: user_details['id']).first
              if user
                # login
                store_authenticated_user(user)
                @path = after_login_page.path
              else
                # register with details
                @path = join_page.path + '?'
                @path += "first_name=#{CGI.escape(user_details['first_name'])}"
                @path += "&last_name=#{CGI.escape(user_details['last_name'])}"
                @path += "&email=#{CGI.escape(user_details['email'])}"
                @path += "&oauth_id=#{CGI.escape(user_details['id'])}"
              end
            end
          end
        end
      ensure
        @path = join_page.path if @path.nil?
        return "<html><script>window.opener.location.href = '#{@path}';window.close();</script></html>"
      end
    end
  end
  
  def get_https(path)
    https = Net::HTTP.new(GRAPH_DOMAIN, 443)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    https.start do
      req = Net::HTTP::Get.new(path)
      return https.request(req).read_body
    end
  end
end
