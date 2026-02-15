class CreateQuoteRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :quote_requests do |t|
      t.references :maintenance_request, null: false, foreign_key: true
      t.references :vendor, null: false, foreign_key: true
      t.integer :status, default: 0, null: false

      t.timestamps
    end
    add_index :quote_requests, [ :maintenance_request_id, :vendor_id ], unique: true
  end
end
