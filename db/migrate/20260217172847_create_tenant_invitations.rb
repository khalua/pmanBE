class CreateTenantInvitations < ActiveRecord::Migration[7.2]
  def change
    create_table :tenant_invitations do |t|
      t.references :unit, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :code, null: false
      t.string :tenant_name, null: false
      t.string :tenant_email, null: false
      t.references :claimed_by, foreign_key: { to_table: :users }
      t.datetime :expires_at, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :tenant_invitations, :code, unique: true
  end
end
