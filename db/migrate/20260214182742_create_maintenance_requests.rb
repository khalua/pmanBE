class CreateMaintenanceRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :maintenance_requests do |t|
      t.string :issue_type
      t.string :location
      t.integer :severity, default: 0
      t.integer :status, default: 0
      t.text :conversation_summary
      t.boolean :allows_direct_contact
      t.references :tenant, null: false, foreign_key: { to_table: :users }
      t.references :assigned_vendor, null: true, foreign_key: { to_table: :vendors }

      t.timestamps
    end
  end
end
