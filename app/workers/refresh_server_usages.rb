class RefreshServerUsages
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    Server.select('id, user_id').each do |server|
      begin
        refresh_server_usages(server)
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { source: 'RefreshServerUsages', server_id: server.id })
      end
    end
    # TODO: Verify and report usage exceeding limit
  end
  
  def refresh_server_usages(server)
    manager.perform(:refresh_cpu_usages, server.user_id, server.id)
    manager.perform(:refresh_network_usages, server.user_id, server.id)
  end
  
  def manager
    @manager ||= ServerTasks.new
  end
end
