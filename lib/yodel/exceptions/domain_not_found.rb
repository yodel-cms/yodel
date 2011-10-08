class DomainNotFound < StandardError
  attr_reader :domain
  def initialize(domain, port)
    @domain = domain
    @port = (port == 80 ? nil : port)
    super()
  end
  
  def error
    ["#{@domain} isn't set up"]
  end
  
  def description
    "<form action='http://yodel#{':' if @port}#{@port}/sites' method='post' class='inline'><input type='hidden' name='name'' value='#{@domain}'><a href='#' onclick='submit()'>Create a new site</a></form> or try a different address."
  end
end
