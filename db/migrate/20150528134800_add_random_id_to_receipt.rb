class AddRandomIdToReceipt < ActiveRecord::Migration
  def change
    add_column :receipts, :random_id, :string
  end
end
