class AddFieldsToVendors < ActiveRecord::Migration[7.2]
  def change
    add_column :vendors, :contact_name, :string
    add_column :vendors, :cell_phone, :string
    add_column :vendors, :email, :string
    add_column :vendors, :address, :string
    add_column :vendors, :website, :string
    add_column :vendors, :notes, :text
    add_column :vendors, :owner_user_id, :bigint
    add_foreign_key :vendors, :users, column: :owner_user_id
    add_index :vendors, :owner_user_id
  end
end
