class AddStatusToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :status, :integer
  end
end
