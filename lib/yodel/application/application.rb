module Yodel
  class Application < Rack::Builder
    def initialize
      super
      
      # boot
      Yodel.config.merge_defaults!
      Yodel.load_extensions
      Dir.chdir(Yodel.config.root)
      
      # serve files from public in development. the directories are
      # initialised in reverse order so the apps public directory
      # takes first precedence over any extensions.
      if Yodel.env.development?
        Yodel.use_middleware do |app|
          Yodel.config.public_directories.reverse.each do |directory|
            app.use Yodel::ConditionalFile, directory
          end
        end
      end
      
      # setup middleware
      use Rack::NestedParams
      use Rack::MethodOverride
      use Rack::Session::Cookie, key: Yodel.config.session_key, secret: Yodel.config.session_secret
      Yodel.initialise_middleware_with_app(self)
      
      # check for any remaining migrations
      Yodel::Migration.remaining_migrations.each do |site, remaining|
        next if remaining.empty?
        Yodel.config.logger.warn "Remaining migrations for site #{site.name}:"
        remaining.each {|name| Yodel.config.logger.warn name}
        Yodel.config.logger.warn ""
      end
      
      # FIXME: for production, load layouts once
      if Yodel.env.production?
        Yodel::Site.all.each {|site| Yodel::Layout.reload_layouts(site)}
      end
      
      # initialise a rack endpoint
      run Yodel::RequestHandler.new
      @app = to_app
      
      # boot complete
      Yodel.config.logger.info "Yodel startup complete"
    end

    def call(env)
      @app.call(env)
    end
  end
end
