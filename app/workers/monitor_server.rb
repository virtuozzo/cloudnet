class MonitorServer
  POLL_INTERVAL = 30
  include Sidekiq::Worker
  attr_reader :server
  
  def perform(server_id, user_id, docker_provision = false)
    return unless server_id
    return if Server.find_by_id(server_id).nil?

    manager = ServerTasks.new
    @server  = manager.perform(:refresh_server, user_id, server_id, docker_provision)
    manager.perform(:refresh_events, user_id, server_id)

    pending_events = server.server_events.where.not(status: :complete)

    if still_monitor? || has_no_ip_address? || pending_events.size > 0
      MonitorServer.perform_in(MonitorServer::POLL_INTERVAL.seconds, server_id, user_id, docker_provision)
    end
  end
  
  def still_monitor?
    server.state != :on && 
    server.state != :off && 
    server.state != :blocked &&
    server.state != :provisioning
  end
  
  def has_no_ip_address?
    server.server_ip_addresses.first.try(:address).nil?
  end
end
