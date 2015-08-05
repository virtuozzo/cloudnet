class RefreshAllServers
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform
    VCD.poll_all
    
    Server.select('id, user_id').each do |server|
      begin
        manager = ServerTasks.new
        manager.perform(:refresh_server, server.user_id, server.id)
        manager.perform(:refresh_events, server.user_id, server.id)
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { source: 'RefreshAllServers', server_id: server.id })
      end
    end
  end
end
