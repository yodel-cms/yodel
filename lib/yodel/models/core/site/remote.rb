class Remote < MongoRecord
  collection :remotes
  field :name, :string, validations: {required: {}}
  field :url, :string, validations: {required: {}}
  field :username, :string, validations: {required: {}}
  field :password, :password, validations: {required: {}}
  many  :sites, store: false
end
