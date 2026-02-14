class CreateVendors < ActiveRecord::Migration[7.2]
  def change
    create_table :vendors do |t|
      t.string :name
      t.string :phone_number
      t.decimal :rating
      t.boolean :is_available
      t.string :location
      t.integer :vendor_type
      t.text :specialties

      t.timestamps
    end
  end
end
