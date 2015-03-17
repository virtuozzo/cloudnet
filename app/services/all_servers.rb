class AllServers
  def process
    squall = Squall::VirtualMachine.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
    squall.list
  end
end
