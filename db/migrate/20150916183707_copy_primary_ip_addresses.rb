class CopyPrimaryIpAddresses < ActiveRecord::Migration
  def change
    # Copy primary IP addresses of deleted servers to new table
    Server.only_deleted.each do |server|
      ServerIpAddress.new(
      address: server.read_attribute(:primary_ip_address),
      server_id: server.id,
      primary: true,
      deleted_at: server.deleted_at).save(validate: false)
    end
    
    # Get IP data from OnApp
    RefreshIpAddresses.perform_async
  end
end
