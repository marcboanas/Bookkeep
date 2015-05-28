# == Schema Information
#
# Table name: users
#
#  id                 :integer          not null, primary key
#  email              :string
#  first_name         :string
#  last_name          :string
#  password_hash      :string
#  password_salt      :string
#  email_verification :string           default("f")
#  verification_code  :string
#  api_authtoken      :string
#  authtoken_expiry   :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  admin              :boolean          default(FALSE)
#

require "rails_helper"

RSpec.describe User, :type => :model do
  before { @user = User.new(first_name: "Example", last_name: "User", email: "user@example.com", password: "Password123", password_confirmation: "Password123") }

  subject { @user }

  it { should respond_to(:first_name) }
  it { should respond_to(:last_name) }
  it { should respond_to(:email) }
  it { should respond_to(:password) }
  it { should respond_to(:password_confirmation) }
  it { should respond_to(:password_hash) }
  it { should respond_to(:password_salt) }
  it { should be_valid }

  describe "when name is not present" do
    before { @user.email = " " }
    it { should_not be_valid }
  end

  describe "when name is too long" do
    before { @user.first_name = "a" * 51 }
    it { should_not be_valid }
  end

  describe "when email format is invalid" do
    it "should be invalid" do
      addresses = %w[user@foo,com user_at_foo.org example.user@foo.foo@bar_baz.com foo@bar+baz.com]
      addresses.each do |invalid_address|
        @user.email = invalid_address
        expect(@user).not_to be_valid
      end
    end
  end

  describe "when email format is valid" do
    it "should be valid" do
      addresses = %w[user@foo.COM A_US-ER@f.b.org frst.1st@foo.jp a+b@baz.cn]
      addresses.each do |valid_address|
        @user.email = valid_address
        expect(@user).to be_valid
      end
    end
  end

  describe "when email address is already taken" do
    before do
      user_with_same_email = @user.dup
      user_with_same_email.email = @user.email.upcase
      user_with_same_email.save
    end

    it { should_not be_valid }
  end

  describe "when password is not present" do
    before do
      @user = User.new(first_name: "Example1", last_name: 'User1', email: "user1@example.com", password: " ", password_confirmation: " ")
    end
    it { should_not be_valid }
  end

  describe "when password doesn't match confirmation" do
    before do
      @user = User.new(first_name: "Example1", last_name: 'User1', email: "user1@example.com", password: "password123", password_confirmation: "mismatch")
    end
    it { should_not be_valid }
  end

  describe "when password matches confirmation" do
    before do
      @user = User.new(first_name: "Example1", last_name: 'User1', email: "user1@example.com", password: "password123", password_confirmation: "password123")
    end
    it { should be_valid }
  end

  describe "with a password that's too short" do
    before { @user.password = @user.password_confirmation = 'a' * 5 }
    it { should be_invalid }
  end

  describe "email address with mixed case" do
    let(:mixed_case_email) { "Foo@ExamPLE.Com"}
    it "should be saved as all lower-case" do
      @user.email = mixed_case_email
      @user.save
      expect(@user.reload.email).to eq mixed_case_email.downcase
    end
  end
end
