class CreateManagerInvitations < ActiveRecord::Migration[7.2]
  def change
    create_table :manager_invitations do |t|
      t.bigint :created_by_id
      t.bigint :claimed_by_id
      t.string :manager_name
      t.string :manager_email
      t.string :code
      t.datetime :expires_at
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :manager_invitations, :created_by_id
    add_index :manager_invitations, :claimed_by_id
    add_index :manager_invitations, :code, unique: true
  end
end
