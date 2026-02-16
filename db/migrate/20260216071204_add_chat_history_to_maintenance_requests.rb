class AddChatHistoryToMaintenanceRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :maintenance_requests, :chat_history, :jsonb, default: []
  end
end
