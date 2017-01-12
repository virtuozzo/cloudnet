class MonitorServer
  POLL_INTERVAL = 30
  include Sidekiq::Worker
  attr_reader :server

  def perform(server_id, user_id, docker_provision = false)
    return unless server_id
    return if Server.find_by_id(server_id).nil?

    manager = ServerTasks.new
    provisioning_status = docker_provision ? :provisioning : false

    @server  = manager.perform(:refresh_server, user_id, server_id, provisioning_status, :monitoring)
    manager.perform(:refresh_events, user_id, server_id)

    pending_events = server.server_events.where.not(status: [:complete, :cancelled, :failed])

    # do not consider old pending events - that might create never ending monitoring tasks
    pending_events = pending_events.select {|e| e.transaction_created > (Time.now - 1.days)}

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
