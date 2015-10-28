class CreateBackup
  include Sidekiq::Worker

  def perform(user_id, server_id)
    DiskTasks.new.perform(:request_backup, user_id, server_id)
    RefreshServerBackups.perform_in(RefreshServerBackups::POLL_INTERVAL.seconds, user_id, server_id)
  end
end
