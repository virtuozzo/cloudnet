class AddInProvisionToServers < ActiveRecord::Migration
  def change
    add_column :servers, :in_provision, :boolean, default: false
  end
end
