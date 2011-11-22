class Remote < MongoRecord
  collection :remotes
  field :name, :string, validations: {required: {}}
  field :url, :string, validations: {required: {}}
  field :username, :string, validations: {required: {}}
  field :password, :password, validations: {required: {}}
  many  :sites, store: false
  
  def site_list
    perform_request('/sites.json', :get)
  end
  
  def create_site
    perform_request('/sites.json', :post)
  end
  
  before_save :hash_password
  def hash_password
    return unless password_changed? && password?
    self.password = Password.hashed_password(nil, password)
  end
  
  def host
    URI.parse(url).host
  end
  
  private
    def perform_request(request_path, method)
      case method
      when :get
        klass = Net::HTTP::Get
      when :post
        klass = Net::HTTP::Post
      else
        raise "Unknown remote request type"
      end
      uri = URI.parse(url)
      
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = klass.new(uri.merge(request_path).path, {'Content-Type' => 'application/json'})
        request.basic_auth username, password
        response = http.request(request, '')
        if response.is_a?(Net::HTTPNotFound)
          {'success' => false, 'reason' => 'Path or domain not found'}
        elsif response.code == 302
          {'success' => false, 'reason'=> 'Redirection not supported'}
        else
          JSON.parse(response.body)
        end
      end
    rescue Errno::ECONNREFUSED
      {'success' => false, 'reason' => 'Remote host could not be contacted'}
    end
end
