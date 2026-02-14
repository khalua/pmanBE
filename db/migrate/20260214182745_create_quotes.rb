class CreateQuotes < ActiveRecord::Migration[7.2]
  def change
    create_table :quotes do |t|
      t.references :vendor, null: false, foreign_key: true
      t.references :maintenance_request, null: false, foreign_key: true
      t.decimal :estimated_cost
      t.datetime :estimated_arrival_time
      t.text :work_description

      t.timestamps
    end
  end
end
