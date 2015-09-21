class RebuildNetwork
  def initialize(server, user)
    @server = server
    @user   = user
  end

  def process
    squall_network = Squall::Network.new(uri: ONAPP_CP[:uri], user: @user.onapp_user, pass: @user.onapp_password)
    squall_network.rebuild(@server.identifier)
  end
end
