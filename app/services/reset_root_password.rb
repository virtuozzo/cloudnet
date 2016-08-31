class ResetRootPassword
  def initialize(server, user)
    @server = server
    @user   = user
  end

  def process
    squall_vm = Squall::VirtualMachine.new(uri: ONAPP_CP[:uri], user: @user.onapp_user, pass: @user.onapp_password)
    squall_vm.change_password(@server.identifier)
    
    MonitorServer.perform_in(MonitorServer::POLL_INTERVAL.seconds, @server.id, @user.id)
  end
end
