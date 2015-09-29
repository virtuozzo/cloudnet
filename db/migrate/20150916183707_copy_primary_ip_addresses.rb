class CopyPrimaryIpAddresses < ActiveRecord::Migration
  def change
    # Copy primary IP addresses of all servers to server_ip_addresses table
    Server.with_deleted.each do |server|
      ServerIpAddress.new(
      address: server.read_attribute(:primary_ip_address),
      server_id: server.id,
      primary: true,
      deleted_at: server.deleted_at).save(validate: false)
    end
  end
end
