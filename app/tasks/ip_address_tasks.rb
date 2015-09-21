class IpAddressTasks < BaseTasks
  def perform(action, user_id, server_id, *args)
    user    = User.find(user_id)
    server  = Server.find(server_id)

    squall = Squall::IpAddressJoin.new(uri: ONAPP_CP[:uri], user: user.onapp_user, pass: user.onapp_password)
    run_task(action, server, squall, *args)
  end
  
  private

  # Fetch IP addresses from Onapp and update or insert them into the database
  def refresh_ip_addresses(server, squall)
    ip_addresses = squall.list(server.identifier)
    ip_addresses.each do |ip_address|
      ip_attrs = ip_address['ip_address']
      primary = server.server_ip_addresses.empty?
      server.server_ip_addresses.where(identifier: ip_address['id'].to_s).first_or_initialize(
        address: ip_attrs['address'],
        netmask: ip_attrs['netmask'],
        network: ip_attrs['network_address'],
        broadcast: ip_attrs['broadcast'],
        gateway: ip_attrs['gateway'],
        primary: primary
      ).save
    end
    # Finally, remove any non-existing IP addresses
    # server.server_ip_addresses.where(["identifier NOT IN (?)", ip_addresses.map {|ip| ip["id"].to_s}]).map(&:destroy)
  end
  
  def assign_ip(server, squall)
    squall.assign(server.identifier, {:network_interface_id => server.primary_network_interface['id']})
  end
  
  def remove_ip(server, squall, ip_address_identifier)
    squall.delete(server.identifier, ip_address_identifier)
  end

  def allowable_methods
    super + [:refresh_ip_addresses, :assign_ip, :remove_ip]
  end
end
