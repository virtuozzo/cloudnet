class DiskTasks < BaseTasks
  def perform(action, user_id, server_id, *args)
    user    = User.find(user_id)
    server  = Server.find(server_id)

    squall  = Squall::Disk.new(uri: ONAPP_CP[:uri], user: user.onapp_user, pass: user.onapp_password)
    run_task(action, server, squall, *args)
  end
  
  def request_backup(server, squall)
    primary_disk = get_primary_disk(server, squall)
    squall.request_backup(primary_disk['id'])
  end
  
  # Fetch backups from Onapp and insert them into the database
  def refresh_backups(server, squall)
    primary_disk = get_primary_disk(server, squall)
    backups   = squall.backups(primary_disk['id'])
    new_backup_created = false
    backups.each do |backup|
      backup_attrs = {
        backup_id:          backup['id'],
        built:              backup['built'],
        built_at:           backup['built_at'],
        backup_created:     backup['created_at'],
        identifier:         backup['identifier'],
        locked:             backup['locked'],
        disk_id:            backup['disk_id'],
        min_disk_size:      backup['min_disk_size'],
        min_memory_size:    backup['min_memory_size'],
        backup_size:        backup['backup_size']
      }
      server_backup = server.server_backups.where(identifier: backup['identifier']).first
      if server_backup
        server_backup.update(backup_attrs)
      else
        new_backup = server.server_backups.create(backup_attrs)
        MonitorBackup.perform_in(MonitorBackup::POLL_INTERVAL.seconds, server.id, new_backup.id, server.user_id)
        new_backup_created = true
      end
    end
    # Destroy backup objects that do not exist at Onapp
    server.server_backups.where(["identifier NOT IN (?)", backups.map {|b| b["identifier"]}]).map(&:destroy)
    new_backup_created
  end
  
  def get_primary_disk(server, squall)
    disks         = squall.vm_disk_list(server.identifier)
    disks.select { |disk| disk['primary'] == true }.first
  end

  def allowable_methods
    super + [:request_backup, :refresh_backups]
  end
end
