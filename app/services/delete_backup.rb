class DeleteBackup
  def initialize(server, backup, user)
    @server = server
    @backup = backup
    @user   = user
  end

  def process
    squall = Squall::Backup.new(uri: ONAPP_CP[:uri], user: @user.onapp_user, pass: @user.onapp_password)
    squall.delete(@backup.backup_id)
  end
end
