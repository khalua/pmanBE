class CreateVendorRatings < ActiveRecord::Migration[7.2]
  def change
    create_table :vendor_ratings do |t|
      t.references :vendor, null: false, foreign_key: true
      t.references :maintenance_request, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: { to_table: :users }
      t.integer :stars, null: false
      t.text :comment

      t.timestamps
    end

    add_index :vendor_ratings, [ :vendor_id, :maintenance_request_id ], unique: true
  end
end
