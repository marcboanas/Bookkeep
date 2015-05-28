class CreateReceipts < ActiveRecord::Migration
  def change
    create_table :receipts do |t|
      t.string :title
      t.string :image_url
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
