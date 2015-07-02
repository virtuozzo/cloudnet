class UptimeUpdateServers
  include Sidekiq::Worker
  
  def perform(pingdom_id, days = 30)
    UptimeTasks.new.perform(:update_servers, pingdom_id, days)
  end
end
