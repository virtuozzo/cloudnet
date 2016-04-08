class RefreshServerUsages
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    Server.all.each do |server|
      begin
        refresh_server_usages(server)
        server.inform_if_bandwidth_exceeded
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { source: 'RefreshServerUsages', server_id: server.id })
      end
    end
  end
  
  def refresh_server_usages(server)
    manager.perform(:refresh_cpu_usages, server.user_id, server.id)
    manager.perform(:refresh_network_usages, server.user_id, server.id)
  end
  
  def manager
    @manager ||= ServerTasks.new
  end

end
