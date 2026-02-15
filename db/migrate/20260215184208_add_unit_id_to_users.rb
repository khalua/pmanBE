class AddUnitIdToUsers < ActiveRecord::Migration[7.2]
  def change
    add_reference :users, :unit, null: true, foreign_key: true
  end
end
