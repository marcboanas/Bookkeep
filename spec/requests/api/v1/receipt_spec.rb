require "spec_helper"
require "factories"

describe "BookKeeper API Receipts", :type => :request do
  let(:accept_json) { { "Accept" => "application/json" } }
  let(:json_content_type) { { "Content-Type" => "application/json" } }
  let(:accept_and_return_json) { accept_json.merge(json_content_type) }
  let(:test_user) do
    FactoryGirl.create :user, first_name: "Test", last_name: "Test", email: "test@test.com", password: "Password123", password_confirmation: "Password123", api_authtoken: "123456789", authtoken_expiry: Time.now + (60 * 60 * 24)
  end
  let(:test_user_2) do
    FactoryGirl.create :user, first_name: "Test2", last_name: "Test2", email: "test2@test.com", password: "Password123", password_confirmation: "Password123", api_authtoken: "987654321", authtoken_expiry: Time.now + (60 * 60 * 24)
  end
  let(:test_receipt) do
    FactoryGirl.create :receipt, image_name: "Test_Receipt", title: "Test_Receipt", image_url: "http://www.test.com/123", random_id: "12345", user_id: 1
  end
  let(:test_receipt_2) do
    FactoryGirl.create :receipt, image_name: "Test_Receipt2", title: "Test_Receipt2", image_url: "http://www.test.com/1234", random_id: "54321", user_id: 2
  end
  describe "Get /api/users" do
    it "returns all the receipts for the current user only" do
      test_user
      test_user_2
      test_receipt
      test_receipt_2
      get "/api/receipts", {}, { "Accept" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user.api_authtoken}") }
      expect(response.status).to eq 200
      body = JSON.parse(response.body)
      receipt_titles = body.map { |receipt| receipt["title"] }
      expect(receipt_titles).to match_array(["Test_Receipt"])
    end
  end
end
