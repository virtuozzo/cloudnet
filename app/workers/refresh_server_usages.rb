class RefreshServerUsages
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform
    Server.select('id, user_id').each do |server|
      begin
        manager = ServerTasks.new
        manager.perform(:refresh_cpu_usages, server.user_id, server.id)
        manager.perform(:refresh_network_usages, server.user_id, server.id)
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { source: 'RefreshServerUsages', server_id: server.id })
      end
    end
  end
end
