class DomainNotFound < StandardError
  attr_reader :domain
  def initialize(domain, port)
    @domain = domain
    @port = (port == 80 ? nil : port)
    super()
  end
  
  def error
    ["#{@domain} isn't set up yet"]
  end
  
  def description
    "<a href='http://yodel#{':' if @port}#{@port}/create_site/#{@domain}'>Create a new site</a> or try a different address."
  end
end
