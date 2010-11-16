module Yodel
  def self.object_attribute(name, klass)
    self.class_eval "def self.#{name}; @#{name} ||= #{klass}.new; end"
  end
  
  object_attribute :config, Yodel::Config
  object_attribute :routes, Yodel::RouteSet
end
