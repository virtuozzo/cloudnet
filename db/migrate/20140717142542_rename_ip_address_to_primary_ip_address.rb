class RenameIpAddressToPrimaryIpAddress < ActiveRecord::Migration
  def change
    rename_column :servers, :ip_address, :primary_ip_address
    add_column :servers, :ip_addresses, :integer, default: 1
  end
end
