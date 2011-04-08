module Yodel
  class Trigger < MongoModel
    collection 'triggers'
    field :conditions, Array
    field :actions, Array
  end
end
