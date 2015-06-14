module Api
  module V1
    class ApiController < ApplicationController

      protected

      def correct_user(user)
        @user === user
      end

      def admin?(user)
        user.admin?
      end

      def incorrect_user_error
        render_error_message(401, "You are not the correct user to perform this action!")
      end

      def render_error_message(status, message)
        e = Error.new(:status => status, :message => message)
        render :json => e.to_json, :status => status
      end

      def render_success_message(status, message)
        m = Message.new(:status => status, :message => message)
        render :json => m.to_json, :status => status
      end

      def request_http_token_authentication(realm = "Application")
        self.headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
        render :json => {:error => "HTTP Token: Access denied."}, :status => :unauthorized
      end

      def check_for_valid_authtoken
        authenticate_or_request_with_http_token do |token, options|
          @user = User.where(:api_authtoken => token).first
        end
      end

      def check_authtoken_expiry
        if @user && @user.authtoken_expiry && @user.authtoken_expiry > Time.now
          return true
        else
          render_error_message(401, "Authtoken has expired. Please get a new token and try again!")
        end
      end

      def rand_string(len)
        o = [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
        string = (0..len).map{ o[rand(o.length)] }.join
        return string
      end
    end
  end
end
