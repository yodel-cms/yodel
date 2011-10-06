class Customer < MongoRecord
  collection :customers
  field :name, :string
  field :email, :string
  field :password, :string
  field :sites, :array
  
  def self.login(email, password)
    self.scoped.where(email: email, password: password).first
  end
  
  before_save :hash_password
  def hash_password
    return unless password_changed?
    self.password = Password.hashed_password(nil, self.password)
  end
  
  def sites_json
    sites.collect do |id|
      Site.find_by(_id: id).as_json
    end
  end
end
