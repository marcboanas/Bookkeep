# == Schema Information
#
# Table name: receipts
#
#  id         :integer          not null, primary key
#  title      :string
#  image_url  :string
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  image_name :string
#  random_id  :string
#

require 'rails_helper'

RSpec.describe Receipt, type: :model do
  before {
    @user = User.new(first_name: "Example", last_name: "User", email: "user@example.com", password: "Password123", password_confirmation: "Password123")
    @receipt = Receipt.new(title: "Test", image_name: "Test", image_url: "http://www.test.com/123", random_id: "12345678987654321234", user_id: @user.id)
  }

  subject { @receipt }

  it { should respond_to(:title) }
  it { should respond_to(:image_name) }
  it { should respond_to(:image_url) }
  it { should respond_to(:random_id) }
  it { should respond_to(:user_id) }
  it { should be_valid }
end
