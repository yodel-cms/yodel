module Yodel
  class Trigger < Yodel::SiteRecord
    collection :triggers
    field :conditions, :hash, of: :hash
    field :actions, :array, of: :array
  end
end
