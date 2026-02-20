class AddVendorPortalStatusToQuoteRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :quote_requests, :vendor_contacted_at, :datetime
    add_column :quote_requests, :vendor_work_completed_at, :datetime
  end
end
