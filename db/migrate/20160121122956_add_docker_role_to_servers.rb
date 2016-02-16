class AddDockerRoleToServers < ActiveRecord::Migration
  def change
    add_column :servers, :provisioner_role, :string
  end
end
