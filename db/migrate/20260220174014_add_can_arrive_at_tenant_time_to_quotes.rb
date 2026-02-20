class AddCanArriveAtTenantTimeToQuotes < ActiveRecord::Migration[7.2]
  def change
    add_column :quotes, :can_arrive_at_tenant_time, :boolean
  end
end
