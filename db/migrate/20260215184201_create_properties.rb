class CreateProperties < ActiveRecord::Migration[7.2]
  def change
    create_table :properties do |t|
      t.string :address, null: false
      t.string :name
      t.integer :property_type, default: 0, null: false
      t.references :property_manager, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
