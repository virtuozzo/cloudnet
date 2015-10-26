class BackupsController < ApplicationController
  before_action :set_server
  before_action :set_backup, except: [:index, :create]
  before_action :check_manual_backup_support

  def index
    @backups = @server.server_backups.order(id: :asc)

    respond_to do |format|
      format.html { @backups = @backups.page(params[:page]).per(10) }
      format.json { render json: @backups }
    end
  end

  def create    
    CreateBackup.perform_async(current_user.id, @server.id)
    Analytics.track(current_user, event: 'Created a manual backup', properties: { server_id: @server.id })    
    redirect_to server_backups_path(@server), notice: 'Backup has been requested and will be created shortly'
  rescue Exception => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'Backups#Create' })
    redirect_to server_backups_path, alert: 'Could not schedule backup. Please try again later'
  end

  def restore
    BackupTasks.new.perform(:restore_backup, current_user.id, @server.id, @backup.id)
    MonitorServer.perform_async(@server.id, current_user.id)
    redirect_to server_path(@server), notice: 'Backup restore will occur shortly'
  rescue
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'Backups#Restore' })
    flash.now[:alert] = 'Could not schedule backup restore. Please try again later'
    redirect_to server_backups_path
  end

  def destroy
    BackupTasks.new.perform(:delete_backup, current_user.id, @server.id, @backup.id)
    @backup.destroy!
    redirect_to server_backups_path, notice: 'Backup has been deleted'
  rescue Exception => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'Backups#Destroy' })
    flash.now[:alert] = 'Could not schedule backup destroy. Please try again later'
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
