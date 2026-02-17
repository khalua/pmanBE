class DeleteOrphanTenants < ActiveRecord::Migration[7.2]
  def up
    User.where(role: 0, unit_id: nil).destroy_all
  end

  def down
    # Cannot restore deleted users
  end
end
