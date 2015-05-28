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

class Receipt < ActiveRecord::Base
  belongs_to :user

  def to_json(options={})
    options[:except] ||= [:id, :user_id, :created_at, :updated_at]
    super(options)
  end
end
