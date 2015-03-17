class ServerConsole
  def initialize(server, user)
    @server = server
    @user = user
  end

  def process
    squall = Squall::VirtualMachine.new(uri: ONAPP_CP[:uri], user: @user.onapp_user, pass: @user.onapp_password)
    console = squall.console(@server.identifier)

    {
      port: console['port'],
      remote_key: console['remote_key'],
      console_src: "#{ONAPP_CP[:uri]}/console_remote/#{console['remote_key']}"
    }
  end
end
