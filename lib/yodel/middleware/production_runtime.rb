require File.join(File.dirname(__FILE__), 'git_http')
require 'file_utils'

class ProductionRuntime
  def initialize(app)
    @app = app
    @auth = Rack::Auth::Basic.new(ProductionHandler.new) do |username, password|
      Customer.scoped.exists?(email: username, password: password)
    end
  end
  
  def call(env)
    if env['yodel.site'].nil?
      @auth.call(env)
    else
      @app.call(env)
    end
  end
end

class ProductionHandler
  SITES_PATH  = /^\/sites\/?$/
  SITE_PATH   = /^\/sites\/(.*)$/
  GIT_PATH    = /^\/git\/\w+/
  
  def initialize
    @git_handler = GitHttp::App.new({
      project_root: Yodel.config.sites_root,
      git_path: Yodel.config.git_path,
      upload_pack: true,
      receive_pack: true
    })
  end
  
  def call(env)
    request = Rack::Request.new(env)
    customer = Customer.scoped.where(email: env['REMOTE_USER']).first
    
    if customer
      if request.path =~ SITES_PATH
        case request.request_method.downcase
        when 'get'
          return [200, {'Content-Type' => 'application/json'}, [customer.sites_json.to_json]]
        when 'post'
          # identifiers must be unique
          if Site.where(identifier: params['identifier']).exists?
            return [200, {'Content-Type' => 'application/json'}, [{successful: false, taken: true}.to_json]]
          end
          
          # create a new site
          site = Site.new
          site.name = params['name']
          site.root_directory = File.join(Yodel.config.sites_root, site.id)
          site.domains = params['domains']
          site.save
          
          # give the customer permissions to the site
          customer.sites << site.id
          customer.save
          
          # create a blank repository
          FileUtils.mkdir_p(site.root_directory)
          `git init #{site.root_directory}`
          return [200, {'Content-Type' => 'application/json'}, [{successful: true, id: site.id.to_s}.to_json]]
        end
        
      elsif request.path =~ GIT_PATH
        env['PATH_INFO'] = env['PATH_INFO'][5..-1]
        site = Site.where(identifier: env['PATH_INFO'].split('/').first)
        raise Unauthorised unless customer.sites.include?(site.id)
        return @git_handler.call(env)
      end
    end
    
    [404, {'Content-Type' => 'text/plain'}, ["File (#{request.path}) not found."]]
  end
end
