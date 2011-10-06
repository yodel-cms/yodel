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
      project_root: Yodel.config.sites_root.to_s,
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
          if Site.find_by(identifier: params['identifier']).present?
            return [200, {'Content-Type' => 'application/json'}, [{successful: false, taken: true}.to_json]]
          end
          
          # create a new site
          site = Site.new
          site.name = params['name']
          site.identifier = params['identifier']
          site.site_root = Yodel.config.sites_root.join(params['identifier'])
          site.domains = params['domains']
          site.save
          
          # give the customer permissions to the site
          customer.sites << site.id
          customer.save
          
          # create a blank repository
          FileUtils.mkdir_p(site.site_root.to_s)
          `git init #{site.site_root}`
          return [200, {'Content-Type' => 'application/json'}, [{successful: true, id: site.id.to_s}.to_json]]
        end
        
      elsif request.path =~ SITE_PATH
        site = Site.find_by(_id: $1)
        raise Unauthorised unless customer.sites.include?(site.id)
        case request.request_method.downcase
        when 'get'
          return [200, {'Content-Type' => 'application/json'}, [site.as_json.to_json]]
        when 'post'
          # update the sites identifier if required, ensuring no other sites have the same identifier
          # and moving the site's source and repository to match the new identifier
          if site.identifier != params['identifier']
            if Site.find_by(identifier: params['identifier']).present?
              return [200, {'Content-Type' => 'application/json'}, [{successful: false, taken: true}.to_json]]
            end
            site.identifier = params['identifier']
            dir_was = site.site_root
            site.site_root = Yodel.config.sites_root.join(params['identifier'])
            FileUtils.mv(dir_was, site.site_root)
          end
          
          # update other values
          site.name = params['name']
          site.domains = params['domains']
          site.save
          
          # perform a migration to make the site changes live
          Migration.run_migrations(site)
        end
        
      elsif request.path =~ GIT_PATH
        env['PATH_INFO'] = env['PATH_INFO'][5..-1]
        site = Site.find_by(identifier: env['PATH_INFO'].split('/').first)
        raise Unauthorised unless customer.sites.include?(site.id)
        return @git_handler.call(env)
      end
    end
    
    [404, {'Content-Type' => 'text/plain'}, ["File (#{request.path}) not found."]]
  end
end
