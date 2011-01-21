module Yodel
  def self.routes
    @routes ||= RouteSet.new
  end
end
