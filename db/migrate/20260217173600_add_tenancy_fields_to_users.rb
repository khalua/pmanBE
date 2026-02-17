class AddTenancyFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :move_in_date, :date
    add_column :users, :move_out_date, :date
    add_column :users, :active, :boolean, default: true, null: false
  end
end
