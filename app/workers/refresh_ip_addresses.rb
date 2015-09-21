# This could be a one time task to fetch IP address data for all running servers from OnApp
class RefreshIpAddresses
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform
    Server.select('id, user_id').each do |server|
      begin
        ip_address_task = IpAddressTasks.new
        ip_address_task.perform(:refresh_ip_addresses, server.user_id, server.id)
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { source: 'RefreshIpAddresses', server_id: server.id })
      end
    end
  end
end
