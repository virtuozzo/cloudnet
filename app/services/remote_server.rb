class RemoteServer
  def initialize(identifier)
    @identifier = identifier
    @squall = Squall::VirtualMachine.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
  end

  def show
    @squall.show @identifier
  rescue StandardError => e
    p e
    nil
  end
end
