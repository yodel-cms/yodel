class Remote < MongoRecord
  collection :remotes
  field :name, :string, validations: {required: {}}
  field :url, :string, validations: {required: {}}
  field :username, :string, validations: {required: {}}
  field :password, :password, validations: {required: {}}
  many  :sites, store: false
  
  def site_list
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new(uri.merge('/sites').path, {'Content-Type' => 'application/json'})
      request.basic_auth username, password
      response = http.request(request, '')
      if response.is_a?(Net::HTTPNotFound)
        {success: false, reason: 'Path or domain not found'}
      elsif response.code == 302
        {success: false, reason: 'Redirection not supported'}
      else
        JSON.parse(response.body)
      end
    end
  end
end
