module Api
  module V1
    class SessionsController < Api::V1::ApiController
      before_filter :check_for_valid_authtoken, :except => [:create] #check logged in?
      before_filter :check_authtoken_expiry, :except => [:create] #login still valid?

      # Sign In
      def create
        if request.post?
          if params && params[:email] && params[:password]
            user = User.where(:email => params[:email]).first

            if user
              if User.authenticate(params[:email], params[:password])

                if !user.api_authtoken || (user.api_authtoken && user.authtoken_expiry < Time.now)
                  auth_token = rand_string(20)
                  auth_expiry = Time.now + (60 * 60 * 24)

                  user.update_attributes(:api_authtoken => auth_token, :authtoken_expiry => auth_expiry)
                end
                render :json => user.to_json, :status => :created
              else
                render_error_message(401, "Wrong Password")
              end
            else
              render_error_message(400, "No USER found by this email ID")
            end
          else
            render_error_message(400, "required parameters are missing")
          end
        end
      end

      # Sign Out (Clear Token)
      def destroy
        @user.update_attributes(:api_authtoken => nil, :authtoken_expiry => nil)
        render_success_message(200, "Token cleared")
      end
    end
  end
end
