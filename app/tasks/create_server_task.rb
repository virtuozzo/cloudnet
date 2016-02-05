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
    if @wizard.build_errors.length > 0
      errors.concat @wizard.build_errors
      false
    elsif @server
      prole = @server.provisioner_role
      docker_provision = !prole.nil?
      MonitorServer.perform_in(MonitorServer::POLL_INTERVAL.seconds, @server.id, @user.id, docker_provision)
      DockerCreation.perform_in(MonitorServer::POLL_INTERVAL.seconds, @server.id, prole) if prole
      true
    else
      false
    end
  end
end
