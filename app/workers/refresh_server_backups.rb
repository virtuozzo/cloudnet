class RefreshServerBackups
  POLL_INTERVAL = 15
  include Sidekiq::Worker

  def perform(user_id, server_id, refresh_once = true)
    new_backup_created = ServerTasks.new.perform(:refresh_backups, user_id, server_id)
    
    return if refresh_once
    
    if new_backup_created
      Rails.cache.delete([Server::BACKUP_CREATED_CACHE, server_id])
    else
      RefreshServerBackups.perform_in(RefreshServerBackups::POLL_INTERVAL.seconds, user_id, server_id)
    end
  end
end
