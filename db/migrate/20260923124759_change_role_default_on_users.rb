class ChangeRoleDefaultOnUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_default :users, :role, from: nil, to: "user"
    User.where(role: nil).update_all(role: "user")
  end
end
