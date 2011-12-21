module Rack
  class Server
    
    alias :original_start :start
    def start
      trap(:TERM) do
        if server.respond_to?(:shutdown)
          server.shutdown
        else
          exit
        end
      end
      original_start
    end
    
  end
end
