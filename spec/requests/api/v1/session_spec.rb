require "spec_helper"
require "factories"

describe "BookKeeper API Sessions", :type => :request do
  let(:accept_json) { { "Accept" => "application/json" } }
  let(:json_content_type) { { "Content-Type" => "application/json" } }
  let(:accept_and_return_json) { accept_json.merge(json_content_type) }
  let(:test_user_login) do
    FactoryGirl.create :user, first_name: "Test", last_name: "Test", email: "test@test.com", password: "Password123", password_confirmation: "Password123"
  end
  let(:test_user_logged_in) do
    FactoryGirl.create :user, first_name: "Test", last_name: "Test", email: "test@test.com", password: "Password123", password_confirmation: "Password123", api_authtoken: "123456789", authtoken_expiry: Time.now + (24 * 60 * 60)
  end
  let(:test_user_token_expired) do #admin
    FactoryGirl.create :user, first_name: "Test_Token_Expired", last_name: "Test_Token_Expired", email: "test_token_expired@test.com", password: "Password123", password_confirmation: "Password123", api_authtoken: "123456789", authtoken_expiry: Time.now - (60 * 60 * 24)
  end

  describe "Post /api/sessions" do
    it "creates an authtoken if the email and password match" do
      test_user_login
      login_params = {
        "email"     => "test@test.com",
        "password"  => AESCrypt.encrypt("Password123", ENV["API_AUTH_PASSWORD"])
      }.to_json
      post "/api/sessions", login_params, accept_and_return_json
      expect(response.status).to eq 201 #created

      expect(User.where(:email => "test@test.com").first.api_authtoken).to_not be_empty
      expect(User.where(:email => "test@test.com").first.authtoken_expiry).to be > Time.now
    end
    it "doesn't create an authtoken if the email and password don't match" do
      test_user_login
      login_params = {
        "email"     => "test@test.com",
        "password"  => AESCrypt.encrypt("WrongPassword", ENV["API_AUTH_PASSWORD"])
      }.to_json
      post "/api/sessions", login_params, accept_and_return_json
      expect(response.status).to eq 401 #created

      expect(User.where(:email => "test@test.com").first.api_authtoken).to be_nil
      expect(User.where(:email => "test@test.com").first.authtoken_expiry).to be_nil

      error_message = JSON.parse(response.body)["message"]
      expect(error_message).to eq "Wrong Password"
    end
    it "doesn't create an authtoken if email doesn't exist" do
      test_user_login
      login_params = {
        "email"     => "wrong-email@test.com",
        "password"  => AESCrypt.encrypt("Password123", ENV["API_AUTH_PASSWORD"])
      }.to_json
      post "/api/sessions", login_params, accept_and_return_json
      expect(response.status).to eq 400 #created
      error_message = JSON.parse(response.body)["message"]
      expect(error_message).to eq "No USER found by this email ID"
    end
    it "doesn't create an authtoken without email and password" do
      test_user_login
      login_params = {
        "password"  => AESCrypt.encrypt("Password123", ENV["API_AUTH_PASSWORD"])
      }.to_json
      post "/api/sessions", login_params, accept_and_return_json
      expect(response.status).to eq 400 #created
      error_message = JSON.parse(response.body)["message"]
      expect(error_message).to eq "required parameters are missing"
    end
  end

  describe "DELETE /api/sessions/:id" do
    it "clears the api_authtoken and authtoken_expiry (logging out user)" do
      delete "/api/sessions/clear_token", {}, { "Accept" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user_logged_in.api_authtoken}") }
      expect(response.status).to be 200
      error_message = JSON.parse(response.body)["message"]
      expect(error_message).to eq "Token cleared"
    end
    it "doesn't clears the api_authtoken if the authtoken has expired" do
      delete "/api/sessions/clear_token", {}, { "Accept" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user_token_expired.api_authtoken}") }
      expect(response.status).to be 401
      error_message = JSON.parse(response.body)["message"]
      expect(error_message).to eq "Authtoken has expired. Please get a new token and try again!"
    end
  end
end
