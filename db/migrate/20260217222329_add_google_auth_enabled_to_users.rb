class AddGoogleAuthEnabledToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :google_auth_enabled, :boolean, default: false, null: false
  end
end
