class UptimeAllUpdate
  include Sidekiq::Worker
  sidekiq_options unique: true
  
  def perform
    UptimeTasks.new.perform(:update_all_servers)
  end
end
