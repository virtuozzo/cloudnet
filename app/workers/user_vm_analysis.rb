class UserVmAnalysis
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed
  sidekiq_options :retry => 2
  
  def perform
    update_server_count
    update_user_auto_tags
  end
  
  def update_user_auto_tags
    User.find_each do |user|
      UserAnalytics::UserChangeVmStatus.new(user).tag_user_vm_trend
    end
  end
  
  def update_server_count
    update_vm_count_for_users_with_servers
    set_zero_vm_for_users_without_servers
  rescue => e
    ErrorLogging.new.track_exception(e, extra: { source: 'UserVmAnalysis' })
  end
  
  def update_vm_count_for_users_with_servers
    users_with_servers_recently.each do |user|
      UserAnalytics::ServerCountUpdater.new(user).update_user
    end 
  end
  
  def set_zero_vm_for_users_without_servers(slice_size = 500)
    user_ids_with_no_servers_recently.each_slice(slice_size) do |ids|
      UserAnalytics::ServerCountUpdater.bulk_zero_update(ids)
    end
  end
  
  def users_with_servers_recently
    User.where(id: user_ids_with_servers_recently)
  end
  
  def user_ids_with_servers_recently
    @user_ids_with_servers ||= begin
      start_check = UserServerCount::DO_NOT_COUNT_VM_LASTING_LESS_DAYS.days.ago.midnight
      Server.with_deleted.
        where('deleted_at IS NULL OR deleted_at > ?', start_check).
        pluck('DISTINCT user_id')
    end
  end
  
  def user_ids_with_no_servers_recently
    User.where.not(id: user_ids_with_servers_recently).ids
  end
end