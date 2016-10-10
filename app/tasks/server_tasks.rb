class ServerTasks < BaseTasks
  def perform(action, user_id, server_id, *args)
    user = User.find(user_id)
    server = Server.find(server_id)

    squall = Squall::VirtualMachine.new(uri: ONAPP_CP[:uri], user: user.onapp_user, pass: user.onapp_password)
    run_task(action, server, squall, *args)
  end

  private

  def show(server, squall)
    squall.show(server.identifier)
  end

  def refresh_server(server, squall, *args)
    info = squall.show(server.identifier)
    docker_provision = args[0] == true ? :provisioning : nil
    # Don't update our state if our server is locked
    new_state = server.state
    if info['locked'] == false
      if info['built'] == false
        new_state = :building
      elsif info['booted'] == false
        new_state = :off
        onapp_template = active_template(info["template_id"], server.location_id, server.provisioner_role)
      else
        new_state = docker_provision || :on
        onapp_template = active_template(info["template_id"], server.location_id, server.provisioner_role)
      end
    end
    new_state = :blocked if server.user.servers_blocked? || server.validation_reason > 0
    old_state = server.state

    if old_state != new_state
      server.note_time_of_state_change
      state = new_state
    else
      state = old_state
    end

    server.detect_stuck_state
    old_server_specs = Server.new server.as_json if billing_params_changed?(server, info)

    disk_size = info['total_disk_size'].to_i

    server.update(
      built:                  info['built'],
      suspended:              info['suspended'],
      locked:                 info['locked'],
      remote_access_password: info['remote_access_password'],
      root_password:          info['initial_root_password'],
      hypervisor_id:          info['hypervisor_id'],
      cpus:                   info['cpus'],
      memory:                 info['memory'],
      disk_size:              disk_size > 1 ? disk_size.to_s : server.disk_size,
      os:                     info['operating_system'],
      state:                  state,
      template_id:            onapp_template ? onapp_template.id : server.template_id
    )

    prepare_invoice(server, old_server_specs) if old_server_specs
    server.notify_fault(disk_size <= 1, info['ip_addresses'].blank?)
    
    # For backwards compatibility sake, check if location supports multiple IPs. If it does, then go ahead and schedule a fetch, otherwise extract IP address from server info.
    if server.supports_multiple_ips?
      ip_address_task = IpAddressTasks.new
      ip_address_task.perform(:refresh_ip_addresses, server.user_id, server.id)
    else
      server.server_ip_addresses.where(address: CreateServer.extract_ip(info)).first_or_initialize(primary: true).save
    end

    server
  end

  def refresh_events(server, squall)
    transactions = squall.transactions(server.identifier, 100)

    last_event = ServerEvent.select('reference').order('reference DESC').limit(1)
    last_ref   = (last_event.first.reference if last_event.size >= 1) || -1

    transactions.each do |transaction|
      transaction = transaction['transaction']

      # Ignore all transactions related to market, they just pollute
      next if transaction['action'].include?('market')

      if transaction['id'] <= last_ref
        ServerEvent.where(reference: transaction['id']).update_all(
          transaction_updated: transaction['updated_at'],
          status: transaction['status'],
          action: transaction['action']
        )
      else
        ServerEvent.create(
          transaction_created: transaction['created_at'],
          transaction_updated: transaction['updated_at'],
          status: transaction['status'],
          action: transaction['action'],
          server: server,
          reference: transaction['id']
        )
      end
    end
  end

  def refresh_cpu_usages(server, squall)
    usages = squall.cpu_usages(server.identifier)
    parsed = usages.map do |usage|
      usage = usage['cpu_hourly_stat']
      usage.select { |k, _v| k == 'created_at' || k == 'cpu_time' }
    end

    cpu_type = server.server_usages.find_or_initialize_by(usage_type: :cpu)
    cpu_type.usages = parsed.to_json
    cpu_type.save!
  end

  def get_network_interfaces(server, squall)
    squall.network_interfaces(server.identifier)
  end

  def refresh_network_usages(server, squall)
    interfaces = squall.network_interfaces(server.identifier)
    primary = interfaces.find { |interface| interface['network_interface']['primary'] == true }
    return unless primary.present?

    usages = squall.network_usages(server.identifier, primary['network_interface']['id'])
    parsed = usages.map do |usage|
      usage = usage['net_hourly_stat']
      usage.select { |k, _v| k == 'created_at' || k == 'data_received' || k == 'data_sent' }
    end

    network_type = server.server_usages.find_or_initialize_by(usage_type: :network)
    network_type.usages = parsed.to_json
    network_type.save!
  end

  def reboot(server, squall)
    squall.reboot(server.identifier)
    server.update_attribute :state, :rebooting
    server
  end

  def shutdown(server, squall)
    squall.shutdown(server.identifier)
    server.update_attribute :state, :shutting_down
    server
  end

  def startup(server, squall)
    squall.startup(server.identifier)
    server.update_attribute :state, :starting_up
    server
  end

  def console(server, squall)
    response = squall.console(server.identifier)

    {
      called_in_at: response['called_in_at'],
      port: response['port'],
      remote_key: response['remote_key']
    }
  end

  def destroy(server, squall)
    response = squall.delete(server.identifier)
  end

  def allowable_methods
    [
      :show,
      :refresh_server,
      :refresh_events,
      :refresh_cpu_usages,
      :refresh_network_usages,
      :edit,
      :reboot,
      :shutdown,
      :startup,
      :console,
      :destroy,
      :get_network_interfaces
    ] + super
  end

  def active_template(template_id, location_id, provisioner_role)
    if provisioner_role.blank?
      Template.where(identifier: template_id, location_id: location_id).where.not(os_distro: 'docker').first
    else
      Template.where(identifier: template_id, location_id: location_id, os_distro: 'docker').first
    end
  end

  # When changing VM parameters we immediatelly update local DB
  # and generate credit_note for unused time and a new invoice.
  # When syncing with OnApp these params should stay intact
  # If that is not the case - most probably the 'edit' operation failed
  # In that case we need to update billing (credit_note + invoice)
  # It is important that server is not refreshed during 'edit' operation - no_refresh: true
  def billing_params_changed?(server, info)
    # Do not process if server is being created
    return false if info['locked'] == true || info['built'] == false
    disk_size = info['total_disk_size'].to_i

    # For unknown reason the storage can be faulty and not attached to VM
    (server.disk_size.to_i != disk_size && disk_size > 1) ||
    server.cpus != info['cpus'] ||
    server.memory != info['memory']
  end

  def prepare_invoice(server, old_server_specs)
    old_server_specs.create_credit_note_for_time_remaining
    server.charge_wallet
    server.charging_paperwork
  end

end
