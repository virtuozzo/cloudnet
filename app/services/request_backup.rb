class RequestBackup
  def initialize(server, user)
    @server = server
    @user   = user
  end

  def process
    squall_disk   = Squall::Disk.new(uri: ONAPP_CP[:uri], user: @user.onapp_user, pass: @user.onapp_password)
    disks         = squall_disk.vm_disk_list(@server.identifier)
    primary_disk  = disks.select { |disk| disk['primary'] == true }.first

    squall_disk.request_backup(primary_disk['id'])
  end
end
