class CreatePhoneVerifications < ActiveRecord::Migration[7.2]
  def change
    create_table :phone_verifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :phone_number
      t.string :code
      t.datetime :verified_at
      t.datetime :expires_at

      t.timestamps
    end
  end
end
