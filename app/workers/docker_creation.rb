class DockerCreation
  include Sidekiq::Worker
  sidekiq_options :retry => 5
  POLL_INTERVAL = 30.seconds
  attr_reader :server
  
  def perform(server_id, role)
    return unless server_id && Server.find(server_id)
    @server = Server.find(server_id)
    # Do not provision if server under validation
    return unless server.can_provision?

    if server_booted? && server_has_ip? && no_pending_events?
      DockerProvision.perform_async(server_id, role)
    else
      DockerCreation.perform_in(POLL_INTERVAL, server_id, role)
    end
  end
  
  def server_booted?
    server.state.in?([:provisioning])
  end
  
  def server_has_ip?
    server.server_ip_addresses.first.try(:address)
  end
  
  def no_pending_events?
    server.server_events.where.not(status: :complete).size == 0
  end
  
end
