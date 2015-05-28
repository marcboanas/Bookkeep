module Api
  module V1
    class ReceiptsController < Api::V1::ApiController
      before_filter :check_for_valid_authtoken, :except => [] #check logged in?
      before_filter :check_authtoken_expiry, :except => [] #login still valid?

      def index
        receipts = @user.receipts
        render :json => receipts.to_json, :status => 200
      end

      def create
        if request.post?
          if params[:title] && params[:image]
            rand_id = rand_string(40)
            image_name = params[:image].original_filename
            image = params[:image].read
            s3 = AWS::S3.new
            if s3
              bucket = s3.buckets[ENV["S3_BUCKET_NAME"]]
              if !bucket
                bucket = s3.buckets.create(ENV["S3_BUCKET_NAME"])
              end
              s3_object = bucket.objects[rand_id]
              s3_object.write(image, :acl => :public_read)
              image_url = s3_object.public_url.to_s
              receipt = Receipt.new(:image_name => image_name, :user_id => @user.id, :title => params[:title], :image_url => image_url, :random_id => rand_id)
              if receipt.save
                render :json => receipt.to_json
              else
                error_str = ""
                receipt.errors.each{ |attr, msg|
                  error_str += "#{attr} - #{msg},"
                }
                render_error_message(400, error_str)
              end
            else
              render_error_message(401, "AWS S3 signature is wrong!")
            end
          else
            render_error_message(400, "required parameters are missing")
          end
        end
      end

      def destroy
        if request.delete?
          if params[:receipt_id]
            receipt = Receipt.where(:random_id => params[:receipt_id]).first
            if receipt && (receipt.user_id == @user.id || admin?(@user))
              s3 = AWS::S3.new
              if s3
                bucket = s3.buckets[ENV["S3_BUCKET_NAME"]]
                s3_object = bucket.objects[receipt.random_id]
                s3_object.delete
                receipt.destroy
                render_success_message(200, "Image deleted")
              else
                render_error_message(401, "AWS S3 signature is wrong")
              end
            else
              render_error_message(401, "Invalid receipt id or you don't have permission to delete this receipt!")
            end
          else
            render_error_message(400, "required parameters are missing")
          end
        end
      end

      private

      def receipt_params
        params.require(:receipt).permit(:image_name, :title, :user_id, :random_id, :image_url)
      end
    end
  end
end
