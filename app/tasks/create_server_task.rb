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
      server.process_addons unless @wizard.addon_ids.blank?
      server.install_ssh_keys(@wizard.ssh_key_ids) if ENV['DOCKER_PROVISIONER'].present? && !@wizard.ssh_key_ids.blank?
      create_sift_events
      true
    else
      false
    end
  end
  
  def create_sift_events
    order_status = server.validation_reason > 0 ? "$held" : "$approved"
    description = server.validation_reason > 0 ? Account::FraudValidator::VALIDATION_REASONS[server.validation_reason] : nil
    order_properties = {
      "$user_id"        => user.id,
      "$order_id"       => @wizard.invoice.id,
      "$source"         => "$automated",
      "$order_status"   => order_status,
      "$description"    => description
    }
    CreateSiftEvent.perform_async("$order_status", order_properties)
    CreateSiftEvent.perform_async("create_server", server.sift_server_properties)
  rescue StandardError => e
    ErrorLogging.new.track_exception(e, extra: { user: user.id, source: 'CreateServerTask#create_sift_events' })
  end
end
