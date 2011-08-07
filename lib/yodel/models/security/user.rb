class User < Record
  SALT_ALPHABET = (65..90).to_a
  SALT_LENGTH = 40
  PASS_LENGTH = 8

  # create a random salt for new users
  before_create :create_salt_and_hash_password
  def create_salt_and_hash_password
    self.password_salt = ''
    SALT_LENGTH.times {self.password_salt += SALT_ALPHABET.sample.chr}
    self.password_salt = Digest::SHA1.hexdigest(password_salt)
    hash_password
  end

  # whenever the password is updated, re-hash it
  before_save :hash_password
  def hash_password
    return unless password_changed? && password? && password_salt?
    self.password = hashed_password(password)
  end
  
  # check if a plain text password matches the hashed, salted password
  def passwords_match?(password)
    self.password_was == hashed_password(password) ? self : nil
  end
  
  # create and set a new password for this user, returning the new plain text password
  def reset_password
    self.password = ''
    PASS_LENGTH.times {self.password += SALT_ALPHABET.sample.chr}
    self.password.tap {self.save}
  end

  protected
    def hashed_password(password)
      Digest::SHA1.hexdigest("#{password_salt}:#{password}")
    end
end
