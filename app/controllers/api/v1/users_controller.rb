module Api
  module V1
    class UsersController < Api::V1::ApiController
      before_filter :http_authenticate, :only => [:create] #check api authentication
      before_filter :check_for_valid_authtoken, :except => [:create] #check logged in?
      before_filter :check_authtoken_expiry, :except => [:create] #login still valid?

      respond_to :json

      def index
        if admin?(@user)
          respond_with User.all
        else
          incorrect_user_error
        end
      end

      def show
        user = User.find(params[:id])
        if correct_user(user) || admin?(@user)
          respond_with user
        else
          incorrect_user_error
        end
      end

      def create
        if request.post?
          if params && params[:email] && params[:password]
            params[:user] = Hash.new
            params[:user][:first_name] = params[:first_name]
            params[:user][:last_name] = params[:last_name]
            params[:user][:email] = params[:email]

            begin
              decrypted_password = AESCrypt.decrypt(params[:password], ENV["API_AUTH_PASSWORD"])
            rescue Exception => e
              decrypted_password = nil
            end

            params[:user][:password] = decrypted_password
            params[:user][:password_confirmation] = decrypted_password
            params[:user][:verification_code] = rand_string(20)

            user = User.new(user_params)

            if user.save
              respond_with user do |format|
                format.json { render json: @user.to_json, status: :created }
              end
            else
              error_str = ""
              user.errors.each{|attr, msg|
                error_str += "#{attr} - #{msg},"
              }
              render_error_message(400, error_str)
            end
          else
            render_error_message(400, "required parameters are missing")
          end
        end
      end

      def update
        user = User.find(params[:id])
        if correct_user(user) || admin?(@user)
          @updated_user = User.update(user.id, user_params)
          respond_with @user do |format|
            format.json { render json: @updated_user.to_json, status: 200 }
          end
        else
          incorrect_user_error
        end
      end

      def destroy
        user = User.find(params[:id])
        if correct_user(user) || admin?(@user)
          User.delete(user)
          head :no_content
        else
          incorrect_user_error
        end
      end

      private

      def user_params
        params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
      end
    end
  end
end
