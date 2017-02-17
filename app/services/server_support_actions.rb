class ServerSupportActions < Struct.new(:user)

  def server_check(params, ip)
    @server_check ||= ServerWizard.new(default_params(params, ip).merge(params))
  end

  def prepare_edit(edited_server, params)
    server = edited_server.dup
    server.edit(params, false)
    # Bit of an ugly hack to piggy back off the server wizard. We're pretending as if the current
    # server with new specs is being asked to be built from scratch - that's what the wizard was
    # orginally designed to do, ie; building servers from scratch.
    server_hash = server.attributes.slice(*ServerWizard::ATTRIBUTES.map(&:to_s))
    edit_wizard = ServerWizard.new server_hash
    edit_wizard.addon_ids = params["addon_ids"]
    edit_wizard.existing_server_id = edited_server.id
    edit_wizard.card = user.account.billing_cards.first
    edit_wizard.user = user
    edit_wizard.ip_addresses = edited_server.ip_addresses
    edit_wizard.hostname = edited_server.hostname
    edit_wizard
  end

  def update_edited_server(server, params, edit_wizard)
    unless server.disk_size == edit_wizard.disk_size
      # 1 GB used for swap
      # TODO: check for Windows
      params["disk_size"] = (params["disk_size"].to_i + 1).to_s
      edit_wizard.disk_size += 1
    end
    server.no_auto_refresh! if edit_wizard.server_changed?
    server.edit(params)
    server.update_attribute(:bandwidth, edit_wizard.bandwidth) if edit_wizard.server_changed?
  end

  def schedule_edit(edit_wizard, old_server_specs)
    # Send the old server so that a credit note can be issued for it
    edit_wizard.edit_server(old_server_specs)
    edit_wizard
  end

  def schedule_task(task, server_id, monitor = true)
    ServerTasks.new.perform(task, user.id, server_id)
    MonitorServer.perform_in(MonitorServer::POLL_INTERVAL.seconds, server_id, user.id) if monitor
  end

  def default_params(params, ip)
    { location_id: Template.find(params[:template_id]).location.id,
      name: auto_server_name,
      hostname: auto_server_name.parameterize,
      provisioner_role: nil,
      ip_addresses: 1,
      validation_reason: user.account.fraud_validation_reason(ip),
      user: user
    }
  end

  def auto_server_name
    "#{user.full_name} Server #{user.servers.count + 1}"
  end

  def build_api_errors
    return '' unless any_server_check_errors?
    build_api_error_message
  end

  def any_server_check_errors?
    @server_check.build_errors.any? || @server_check.errors.any?
  end

  def build_api_error_message
    error = {}
    error.merge! build: @server_check.build_errors if @server_check.build_errors.any?
    error.merge! @server_check.errors.messages.each_with_object({}) { |e, m| m[e[0]] = e[1] }
    { "error" => error }
  end
end
