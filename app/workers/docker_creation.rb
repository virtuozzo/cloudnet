class DockerCreation
  include Sidekiq::Worker
  sidekiq_options :retry => 5
  POLL_INTERVAL = 30.seconds
  attr_reader :server
  
  def perform(server_id, role)
    return unless server_id && Server.find(server_id)
    @server = Server.find(server_id)

    if server_booted? && server_has_ip?
      DockerProvision.perform_async(server_id, role)
    else
      DockerCreation.perform_in(POLL_INTERVAL, server_id, role)
    end
  end
  
  # FIXME: RefreshAllServers may set server to :on independently
  def server_booted?
    server.state.in?([:provision, :on])
  end
  
  def server_has_ip?
    server.server_ip_addresses.first.try(:address)
  end
  
end