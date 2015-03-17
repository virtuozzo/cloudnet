class AddIpAddressesToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :ip_addresses, :integer, default: 1
  end
end
