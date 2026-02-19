class AddIsActiveToPropertyManagerVendors < ActiveRecord::Migration[7.2]
  def change
    add_column :property_manager_vendors, :is_active, :boolean, default: true, null: false
  end
end
