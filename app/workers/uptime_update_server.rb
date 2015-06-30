class UptimeUpdateServer
  include Sidekiq::Worker
  
  def perform(pingdom_id, location_id, days = nil)
    UptimeTasks.new.perform(:update_server, pingdom_id, location_id, nil, days)
  end
end
