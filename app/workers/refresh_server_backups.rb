class RefreshServerBackups
  POLL_INTERVAL = 15
  include Sidekiq::Worker

  def perform(user_id, server_id)
    new_backup_created = DiskTasks.new.perform(:refresh_backups, user_id, server_id)
    
    unless new_backup_created
      RefreshServerBackups.perform_in(RefreshServerBackups::POLL_INTERVAL.seconds, user_id, server_id)
    end
  end
end
