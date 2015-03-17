class AddDeleteIpAddressToServer < ActiveRecord::Migration
  def change
    add_column :servers, :delete_ip_address, :string
  end
end
