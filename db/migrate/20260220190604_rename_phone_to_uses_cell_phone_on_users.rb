class RenamePhoneToUsesCellPhoneOnUsers < ActiveRecord::Migration[7.2]
  def change
    rename_column :users, :mobile_phone, :cell_phone
    remove_column :users, :phone, :string
    remove_column :users, :home_phone, :string
  end
end
