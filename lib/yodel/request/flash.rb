module Yodel
  class Flash
    def initialize(session)
      @session = session
      @last_request = @session['flash'] || {}
      @this_request = {}
    end
    
    def finalize
      @session['flash'] = @this_request
    end
    
    def [](key)
      @this_request[key] || @last_request[key]
    end
    
    def now(key, value)
      @last_request[key] = value
    end
    
    def []=(key, value)
      @this_request[key] = value
    end
    
    def delete(key)
      @this_request.delete(key)
      @last_request.delete(key)
    end
  end
end
