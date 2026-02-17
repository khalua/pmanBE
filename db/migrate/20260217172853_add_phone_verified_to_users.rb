class AddPhoneVerifiedToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :phone_verified, :boolean, default: false, null: false
  end
end
