class BackupsController < ApplicationController
  before_action :set_server
  before_action :set_backup, except: [:index, :create]
  before_action :check_manual_backup_support

  def index
    respond_to do |format|
      format.html { @backups_count = @server.server_backups.count }
      format.json { @backups = @server.server_backups.order(id: :desc) }
    end
  end

  def create    
    raise "A backup is being built" if @server.server_backups.select {|backup| backup.built == false}.size > 0 or Rails.cache.read([Server::BACKUP_CREATED_CACHE, @server.id])
    CreateBackup.perform_async(current_user.id, @server.id)
    Analytics.track(current_user, event: 'Created a manual backup', properties: { server_id: @server.id })
    Rails.cache.write([Server::BACKUP_CREATED_CACHE, @server.id], true)
    create_sift_event :create_backup, @server.sift_server_properties
    redirect_to server_backups_path(@server), notice: 'Backup has been requested and will be created shortly'
  rescue Exception => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'Backups#Create' })
    redirect_to server_backups_path, alert: 'Could not schedule backup. Please try again later'
  end

  def restore
    BackupTasks.new.perform(:restore_backup, current_user.id, @server.id, @backup.id)
    Analytics.track(current_user, event: 'Restored a backup', properties: { server_id: @server.id })
    MonitorServer.perform_in(MonitorServer::POLL_INTERVAL.seconds, @server.id, current_user.id)
    create_sift_event :restore_backup, @server.sift_server_properties
    redirect_to server_path(@server), notice: 'Backup restore will occur shortly'
  rescue Exception => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'Backups#Restore' })
    flash[:alert] = 'Could not schedule backup restore. Please try again later'
    redirect_to server_backups_path
  end

  def destroy
    BackupTasks.new.perform(:delete_backup, current_user.id, @server.id, @backup.id)
    Analytics.track(current_user, event: 'Deleted a backup', properties: { server_id: @server.id })
    create_sift_event :destroy_backup, @server.sift_server_properties
    flash[:notice] = 'Backup will be deleted shortly'
  rescue Exception => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'Backups#Destroy' })
    flash[:alert] = 'Could not schedule backup destroy. Please try again later'
  ensure
    RefreshServerBackups.perform_in(RefreshServerBackups::POLL_INTERVAL.seconds, current_user.id, @server.id)
    redirect_to server_backups_path
  end

  private

  def set_server
    @server = current_user.servers.find(params[:server_id])
  end

  def set_backup
    @backup = @server.server_backups.find(params[:id])
  end
  
  def check_manual_backup_support
    redirect_to_dashboard unless @server.supports_manual_backups?
  end
end
