class CreateDeviceTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :device_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.string :platform, null: false, default: "ios"

      t.timestamps
    end
    add_index :device_tokens, [ :user_id, :token ], unique: true
  end
end
