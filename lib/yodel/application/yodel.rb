module Yodel
  def self.config
    @config ||= Config.new
  end
end
