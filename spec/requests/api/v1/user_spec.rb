require "spec_helper"
require "factories"

describe "BookKeeper API Users", :type => :request do
  let(:accept_json) { { "Accept" => "application/json" } }
  let(:json_content_type) { { "Content-Type" => "application/json" } }
  let(:accept_and_return_json) { accept_json.merge(json_content_type) }
  let(:test_user) do
    FactoryGirl.create :user, first_name: "Test", last_name: "Test", email: "test@test.com", password: "Password123", password_confirmation: "Password123", api_authtoken: "123456789", authtoken_expiry: Time.now + (60 * 60 * 24)
  end
  let(:test_user_token_expired) do #admin
    FactoryGirl.create :user, first_name: "Test_Token_Expired", last_name: "Test_Token_Expired", email: "test_token_expired@test.com", password: "Password123", password_confirmation: "Password123", api_authtoken: "987654321", authtoken_expiry: Time.now - (60 * 60 * 24), admin: true
  end
  let(:test_user_correct) do
    FactoryGirl.create :user, first_name: "Test_Correct", last_name: "Test_Correct", email: "test_correct@test.com", password: "Password123", password_confirmation: "Password123", api_authtoken: "222555777", authtoken_expiry: Time.now + (60 * 60 * 24)
  end
  let(:test_user_incorrect) do
    FactoryGirl.create :user, first_name: "Test_Incorrect", last_name: "Test_Incorrect", email: "test_incorrect@test.com", password: "Password123", password_confirmation: "Password123", api_authtoken: "999888777", authtoken_expiry: Time.now + (60 * 60 * 24)
  end
  let(:test_user_admin) do
    FactoryGirl.create :user, first_name: "Test_Admin", last_name: "Test_Admin", email: "test_admin@test.com", password: "Password123", password_confirmation: "Password123", api_authtoken: "666888555", authtoken_expiry: Time.now + (60 * 60 * 24), admin: true
  end

  describe "Get /api/users" do
    it "doesn't return all the users if not admin" do
      get "/api/users", {}, { "Accept" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user.api_authtoken}") }
      expect(response.status).to eq 401
    end
    it "returns all the users if admin" do
      test_user
      test_user_2 = FactoryGirl.create :user, first_name: "Test2", last_name: "Test2", email: "test2@test2.com", password: "Password123", password_confirmation: "Password123", api_authtoken: "111112222", authtoken_expiry: Time.now + (60 * 60 * 24)
      get "/api/users", {}, { "Accept" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user_admin.api_authtoken}") }
      expect(response.status).to eq 200
      body = JSON.parse(response.body)
      user_emails = body.map { |user| user["email"] }
      expect(user_emails).to match_array(["test@test.com", "test2@test2.com", "test_admin@test.com"])
    end
    it "doesn't return all the users without authtoken" do
      get "/api/users", {}, accept_json
      expect(response.status).to eq 401
      error_message = JSON.parse(response.body)["error"]
      expect(error_message).to eq "HTTP Token: Access denied."
    end
    it "doesn't return all the users if authtoken has expired" do
      get "/api/users", {}, { "Accept" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user_token_expired.api_authtoken}") }
      expect(response.status).to eq 401
      error_message = JSON.parse(response.body)["message"]
      expect(error_message).to eq "Authtoken has expired. Please get a new token and try again!"
    end
  end

  describe "GET /api/users/:id" do
    it "returns a requested user if correct user" do
      get "/api/users/#{test_user.id}", {}, { "Accept" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user.api_authtoken}") }
      expect(response.status).to eq 200
      body = JSON.parse(response.body)
      expect(body["email"]).to eq "test@test.com"
    end
    it "doesn't return a requested user without authtoken" do
      get "/api/users/#{test_user.id}", {}, accept_json
      expect(response.status).to eq 401
      error_message = JSON.parse(response.body)["error"]
      expect(error_message).to eq "HTTP Token: Access denied."
    end
    it "doesn't return a requested user if authtoken has expired" do
      get "/api/users/#{test_user.id}", {}, { "Accept" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user_token_expired.api_authtoken}") }
      expect(response.status).to eq 401
      error_message = JSON.parse(response.body)["message"]
      expect(error_message).to eq "Authtoken has expired. Please get a new token and try again!"
    end
    it "doesn't return a requested user if not the correct user (or admin)" do
      get "/api/users/#{test_user_incorrect.id}", {}, { "Accept" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user_correct.api_authtoken}") }
      expect(response.status).to eq 401
      error_message = JSON.parse(response.body)["message"]
      expect(error_message).to eq "You are not the correct user to perform this action!"
    end
    it "does return a requested user if admin (even if not correct user)" do
      get "/api/users/#{test_user.id}", {}, { "Accept" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user_admin.api_authtoken}") }
      expect(response.status).to eq 200
      body = JSON.parse(response.body)
      expect(body["email"]).to eq "test@test.com"
    end
  end

  describe "POST /api/users" do
    it "creates a user" do
      # http_login
      user_params = {
        "first_name"            => "Example",
        "last_name"             => "User",
        "email"                 => "example@user2.com",
        "password"              => AESCrypt.encrypt("Password123", ENV["API_AUTH_PASSWORD"]),
        "password_confirmation" => AESCrypt.encrypt("Password123", ENV["API_AUTH_PASSWORD"])
      }.to_json
      post "/api/users", user_params, accept_and_return_json
      expect(response.status).to eq 201 #created
      expect(User.first.email).to eq "example@user2.com"
    end
  end

  describe "PUT /api/users/:id" do

    let(:user_params) do
      { "user" => {
          "email"       => "jcboanas@gmail.com",
          "first_name"  => "John"
        }
      }.to_json
    end

    it "updates a user" do
      patch "/api/users/#{test_user.id}", user_params, { "Accept" => "application/json", "Content-Type" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user.api_authtoken}") }
      expect(response.status).to be 200
      body = JSON.parse(response.body)
      expect(body["first_name"]).to eq "John"
      expect(body["email"]).to eq "jcboanas@gmail.com"
    end
    it "doesn't update a user without authtoken" do
      patch "/api/users/#{test_user.id}", user_params, { "Accept" => "application/json", "Content-Type" => "application/json" }
      expect(response.status).to be 401
      error_message = JSON.parse(response.body)["error"]
      expect(error_message).to eq "HTTP Token: Access denied."
    end
    it "doesn't update a user if authtoken has expired" do
      patch "/api/users/#{test_user.id}", user_params, { "Accept" => "application/json", "Content-Type" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user_token_expired.api_authtoken}") }
      expect(response.status).to eq 401
      error_message = JSON.parse(response.body)["message"]
      expect(error_message).to eq "Authtoken has expired. Please get a new token and try again!"
    end
    it "doesn't update a user if not the correct user" do
      patch "/api/users/#{test_user_correct.id}", user_params, { "Accept" => "application/json", "Content-Type" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user_incorrect.api_authtoken}") }
      expect(response.status).to eq 401
      error_message = JSON.parse(response.body)["message"]
      expect(error_message).to eq "You are not the correct user to perform this action!"
    end
  end

  describe "DELETE /api/users/:id" do

    it "deletes a user if correct user" do
      delete "/api/users/#{test_user.id}", {}, { "Accept" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user.api_authtoken}") }
      expect(response.status).to be 204
      expect(User.all).to eq []
    end
    it "doesn't deletes a user without authtoken" do
      delete "/api/users/#{test_user.id}", {}, { "Accept" => "application/json" }
      expect(response.status).to be 401
      error_message = JSON.parse(response.body)["error"]
      expect(error_message).to eq "HTTP Token: Access denied."
      expect(User.all).to eq [test_user]
    end
    it "doesn't delete a user if authtoken has expired" do
      delete "/api/users/#{test_user_token_expired.id}", {}, { "Accept" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user_token_expired.api_authtoken}") }
      expect(response.status).to eq 401
      error_message = JSON.parse(response.body)["message"]
      expect(error_message).to eq "Authtoken has expired. Please get a new token and try again!"
      expect(User.all).to eq [test_user_token_expired]
    end
    it "doesn't delete a user if not the correct user (and not admin)" do
      delete "/api/users/#{test_user_incorrect.id}", {}, { "Accept" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user_correct.api_authtoken}") }
      expect(response.status).to eq 401
      error_message = JSON.parse(response.body)["message"]
      expect(error_message).to eq "You are not the correct user to perform this action!"
      expect(User.all).to eq [test_user_incorrect, test_user_correct]
    end
    it "deletes a user if the current user is admin (but not the correct user)" do
      delete "/api/users/#{test_user.id}", {}, { "Accept" => "application/json", :authorization => ActionController::HttpAuthentication::Token.encode_credentials("#{test_user_admin.api_authtoken}") }
      expect(response.status).to eq 204
      expect(User.all).to eq [test_user_admin]
    end
  end
end
