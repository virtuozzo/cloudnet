class RemovePrimaryIpAddressFromServers < ActiveRecord::Migration
  def change
    remove_column :servers, :primary_ip_address, :string
  end
end
