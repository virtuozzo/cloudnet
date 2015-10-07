class ServerTasks < BaseTasks
  def perform(action, user_id, server_id, *args)
    user = User.find(user_id)
    server = Server.find(server_id)

    squall = Squall::VirtualMachine.new(uri: ONAPP_CP[:uri], user: user.onapp_user, pass: user.onapp_password)
    run_task(action, server, squall, *args)
  end

  private

  def refresh_server(server, squall)
    info = squall.show(server.identifier)

    # Don't update our state if our server is locked
    new_state = server.state
    if info['locked'] == false
      if info['built'] == false
        new_state = :building
      elsif info['booted'] == false
        new_state = :off
      else
        new_state = :on
      end
    end
    old_state = server.state

    if old_state != new_state
      server.note_time_of_state_change
      state = new_state
    else
      state = old_state
    end

    server.detect_stuck_state

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
      disk_size:              disk_size > 0 ? disk_size.to_s : server.disk_size,
      os:                     info['operating_system'],
      state:                  state,
      primary_ip_address:     CreateServer.extract_ip(info)
    )

    server
  end

  def refresh_events(server, squall)
    transactions = squall.transactions(server.identifier)

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

  def edit(server, squall, *args)
    user = server.user

    # First deal with disk resizing, as it requires a separate API call
    requested_size = args.first
    if requested_size.is_a? Integer
      disk = Squall::Disk.new(uri: ONAPP_CP[:uri], user: user.onapp_user, pass: user.onapp_password)
      disks = disk.vm_disk_list(server.identifier)
      primary = disks.select{|d| d['primary'] == true}.first['id'].to_s
      disk.edit(primary, {disk_size: requested_size})
    end

    # Edit non-disk resources
    options = {
      label: server.name,
      cpus: server.cpus,
      memory: server.memory
    }
    squall.edit(server.identifier, options)
    server
  end

  def reboot(server, squall)
    squall.reboot(server.identifier)
    server.update!(state: :rebooting)
    server
  end

  def shutdown(server, squall)
    squall.shutdown(server.identifier)
    server.update!(state: :shutting_down)
    server
  end

  def startup(server, squall)
    squall.startup(server.identifier)
    server.update!(state: :starting_up)
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
      :refresh_server,
      :refresh_events,
      :refresh_cpu_usages,
      :refresh_network_usages,
      :edit,
      :reboot,
      :shutdown,
      :startup,
      :console,
      :destroy
    ] + super
  end
end
