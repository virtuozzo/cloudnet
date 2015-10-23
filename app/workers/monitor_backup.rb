class MonitorBackup
  POLL_INTERVAL = 15
  include Sidekiq::Worker

  def perform(server_id, backup_id, user_id)
    manager = BackupTasks.new
    backup  = manager.perform(:refresh_backup, user_id, server_id, backup_id)

    if backup.built == false
      MonitorBackup.perform_in(MonitorBackup::POLL_INTERVAL.seconds, server_id, backup_id, user_id)
    end
  end
end
