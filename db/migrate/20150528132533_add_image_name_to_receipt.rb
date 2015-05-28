class AddImageNameToReceipt < ActiveRecord::Migration
  def change
    add_column :receipts, :image_name, :string
  end
end
