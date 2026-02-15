class CreatePropertyManagerVendors < ActiveRecord::Migration[7.2]
  def change
    create_table :property_manager_vendors do |t|
      t.references :user, null: false, foreign_key: true
      t.references :vendor, null: false, foreign_key: true

      t.timestamps
    end
    add_index :property_manager_vendors, [ :user_id, :vendor_id ], unique: true
  end
end
