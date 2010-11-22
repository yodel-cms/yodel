module Yodel
  class Application < Rack::Builder
    def initialize
      super
      
      # boot
      Yodel.config.merge_defaults!
      MongoMapper.connection = Mongo::Connection.new(Yodel.config.database_hostname, Yodel.config.database_port, slave_ok: true)
      MongoMapper.database = Yodel.config.database
      #Yodel.load_extensions(Yodel.config.root.join('app'))
      Dir.chdir(Yodel.config.root)
      
      # serve files from public in development
      if Yodel.env.development?
        Yodel.use_middleware do |app|
          app.use Yodel::ConditionalFile, Yodel.config.public_directory
        end
      end
      
      # setup middleware
      use Rack::NestedParams
      use Rack::Session::Cookie, key: Yodel.config.session_key, secret: Yodel.config.session_secret
      Yodel.initialise_middleware_with_app(self)
      
      # initialise a rack endpoint
      run Yodel::RequestHandler.new
      @app = to_app
    end

    def call(env)
      @app.call(env)
    end
  end
end
