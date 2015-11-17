class MonitorServer
  POLL_INTERVAL = 30
  include Sidekiq::Worker

  def perform(server_id, user_id)
    return unless server_id
    return if Server.find_by_id(server_id).nil?

    manager = ServerTasks.new
    server  = manager.perform(:refresh_server, user_id, server_id)
    manager.perform(:refresh_events, user_id, server_id)

    pending_events = server.server_events.where.not(status: :complete)

    if (server.state != :on && server.state != :off && server.state != :blocked) || pending_events.size > 0
      MonitorServer.perform_in(MonitorServer::POLL_INTERVAL.seconds, server_id, user_id)
    end
  end
end
