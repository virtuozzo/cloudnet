class AddIpAddressFieldToServers < ActiveRecord::Migration
  def change
    add_column :servers, :ip_address, :string
  end
end
