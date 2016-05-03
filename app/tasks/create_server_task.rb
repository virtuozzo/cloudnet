# Creates a server for a *prepaid* account. This was written before the create_payg_server_task
class CreateServerTask < BaseTask
  attr_reader :server, :user

  def initialize(wizard, user)
    super
    @wizard = wizard
    @user   = user
    @server = nil
  end

  def process
    @server = @wizard.create_server
    if @wizard.build_errors.length > 0
      errors.concat @wizard.build_errors
      false
    elsif server
      server.monitor_and_provision
      true
    else
      false
    end
  end
end
