# Creates a server for a *prepaid* account. This was written before the create_payg_server_task
class CreateServerTask < BaseTask
  attr_reader :server

  def initialize(wizard, user)
    super
    @wizard = wizard
    @user   = user
    @server = nil
  end

  def process
    @server = @wizard.create_server
    MonitorServer.perform_in(MonitorServer::POLL_INTERVAL.seconds, @server.id, @user.id)
    if @wizard.build_errors.length > 0
      errors.concat @wizard.build_errors
      false
    else
      true
    end
  end
end
