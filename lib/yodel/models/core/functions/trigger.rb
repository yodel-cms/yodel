module Yodel
  class Trigger < Yodel::SiteRecord
    collection :triggers
    field :conditions, :hash, of: :hash
    field :instructions, :array, of: :array
  end
end
