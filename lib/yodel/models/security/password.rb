module Password
  def self.hashed_password(password_salt, password)
    Digest::SHA1.hexdigest("#{password_salt}:#{password}")
  end
end
