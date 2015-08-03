# Creates a server for a *prepaid* account. This was written before the create_payg_server_task
class CreateVappTask < BaseTask
  attr_reader :server

  def initialize(wizard, user)
    super
    @errors = []
    @wizard = wizard
    @user   = user
    @server = nil
  end

  def process
    VCD.create_vapp @wizard
  end
end
