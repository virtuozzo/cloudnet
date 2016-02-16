class AssignIpAddress
  include Sidekiq::Worker

  def perform(user_id, server_id)
    return if Server.find_by_id(server_id).nil?
    IpAddressTasks.new.perform(:assign_ip, user_id, server_id)
    MonitorServer.perform_in(MonitorServer::POLL_INTERVAL.seconds, server_id, user_id)
  end
end
