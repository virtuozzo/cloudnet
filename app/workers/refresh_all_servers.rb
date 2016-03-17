class RefreshAllServers
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    manager = ServerTasks.new
    Server.where(no_refresh: false).select('id, user_id').each do |server|
      begin
        manager.perform(:refresh_server, server.user_id, server.id)
        manager.perform(:refresh_events, server.user_id, server.id)
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { source: 'RefreshAllServers', server_id: server.id })
      end
    end
  end
end
