module Yodel
  def self.routes
    @config ||= RouteSet.new
  end
end
