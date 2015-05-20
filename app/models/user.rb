class User < ActiveRecord::Base
  attr_accessor :password, :password_confirmation
  before_save :encrypt_password
  before_save { self.email = email.downcase }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: { :on => :create }, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  validates :first_name, length: { maximum: 50 }
  validates :password, length: { in: 6..30 }, :on => :create
  validates_confirmation_of :password, if: lambda { |m| m.password.present? }

  def encrypt_password
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
    end
  end

  def self.authenticate(email, password)
    user = self.where("email =?", email).first

    if user
      puts "******************* #{password} 1"

      begin
        password = AESCrypt.decrypt(password, ENV["API_AUTH_PASSWORD"])
      rescue Exception => e
        password = nil
        puts "error - #{e.message}"
      end

      puts "******************* #{password} 2"

      if user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
        user
      else
        nil
      end
    else
      nil
    end
  end

  def to_json(options={})
    options[:except] ||= [:id, :password_hash, :email_verification, :verification_code, :created_at, :updated_at]
    super(options)
  end
end
