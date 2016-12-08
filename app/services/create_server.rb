class CreateServer
  def initialize(data, user)
    @data = data
    @user = user
  end

  def process
    location = @data.location
    template = @data.template

    squall = Squall::VirtualMachine.new(uri: ONAPP_CP[:uri], user: @user.onapp_user, pass: @user.onapp_password)
    params = {
      label: @data.name,
      hypervisor_group_id: location.hv_group_id,
      hostname: @data.hostname,
      memory: @data.memory,
      cpus: @data.cpus,
      cpu_shares: 100,
      primary_disk_size: @data.disk_size.to_i - template.required_swap,
      template_id: template.identifier,
      required_virtual_machine_build: 1,
      required_virtual_machine_startup: startup_required,
      required_ip_address_assignment: 1
    }

    params.merge!(swap_disk_size: template.required_swap) unless location.provider.scan(/vmware|vcenter/i).length > 0
    params.merge!(rate_limit: location.network_limit) if location.network_limit.present? && location.network_limit > 0
    params.merge!(licensing_type: 'mak') if template.os_type.include?('windows') || template.os_distro.include?('windows')
    params.merge!(note: "Created with #{ENV['BRAND_NAME']} from #{Socket.gethostname}")
    squall.create params
  end

  def self.extract_ip(server)
    ip = '0.0.0.0'
    array = server['ip_addresses']
    if array && array.length >= 1
      return array.first['ip_address']['address']
    end

    ''
  end

  def startup_required
    @data.validation_reason > 0 ? 0 : 1
  end
end
