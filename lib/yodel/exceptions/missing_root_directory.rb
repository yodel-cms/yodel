class MissingRootDirectory < StandardError
  def initialize(site, port)
    @port = (port == 80 ? nil : port)
    @site = site
    super()
  end
  
  def error
    ["The root directory for #{@site.name} is missing"]
  end
  
  def description
    "You can <a href='http://yodel#{':' if @port}#{@port}/sites?id=#{@site.id}'>select a new root directory</a>, or rename the existing directory back to '#{File.basename(@site.root_directory)}'."
  end
end
