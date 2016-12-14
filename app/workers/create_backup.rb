class CreateBackup
  include Sidekiq::Worker

  def perform(user_id, server_id)
    ServerTasks.new.perform(:request_backup, user_id, server_id)
    RefreshServerBackups.perform_in(RefreshServerBackups::POLL_INTERVAL.seconds, user_id, server_id, false)
  end
end
