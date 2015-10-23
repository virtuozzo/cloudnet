class BackupTasks < BaseTasks
  def perform(action, user_id, server_id, backup_id, *args)
    user    = User.find(user_id)
    server  = Server.find(server_id)
    backup  = ServerBackup.find(backup_id)

    squall = Squall::Backup.new(uri: ONAPP_CP[:uri], user: user.onapp_user, pass: user.onapp_password)
    run_task(action, server, squall, backup, *args)
  end

  def refresh_backup(_server, squall, backup)
    info = squall.show(backup.backup_id)
    backup.update!(
      built:              info['built'],
      built_at:           info['built_at'],
      identifier:         info['identifier'],
      locked:             info['locked'],
      disk_id:            info['disk_id'],
      min_disk_size:      info['min_disk_size'],
      min_memory_size:    info['min_memory_size'],
      backup_size:        info['backup_size']
    )

    backup
  end
  
  def delete_backup(_server, squall, backup)
    squall.delete(backup.backup_id)
  end
  
  def restore_backup(_server, squall, backup)
    squall.restore(backup.backup_id)
  end

  def allowable_methods
    super + [:refresh_backup, :delete_backup, :restore_backup]
  end
end
