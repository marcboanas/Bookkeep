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

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
