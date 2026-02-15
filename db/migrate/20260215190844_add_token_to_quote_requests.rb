class AddTokenToQuoteRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :quote_requests, :token, :string, null: false, default: -> { "gen_random_uuid()" }
    add_index :quote_requests, :token, unique: true
  end
end
