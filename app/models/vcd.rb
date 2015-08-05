# A VMWare vApp
class VCD < ActiveRecord::Base
  belongs_to :user
  belongs_to :template
  has_many :servers
  
  def self.poll_all
    VCD.all.each do |vcd|
      vcd.poll
    end
  end
  
  def api
    @api ||= OnappBlanketAPI.new.connection user
  end
  
  def poll
    check_status
    check_vms
  end
  
  def check_status
    details = api.get "/vapps/#{identifier}"
    self.status = details.vapp.status
    self.save!
  end
  
  def check_vms
    vms = api.get "vapps/#{identifier}/associated_virtual_machines"
    return unless vms.count > 0
    vm = vms.virtual_machine
    server = Server.find_or_initialize_by identifier: vm['identifier']
    params = {
      identifier: vm['identifier'],
      name: name,
      hostname: name,
      user: user,
      built: vm['built'],
      suspended: vm['suspended'],
      locked: vm['locked'],
      remote_access_password: vm['remote_access_password'],
      root_password: vm['initial_root_password'],
      hypervisor_id: vm['hypervisor_id'],
      cpus: vm['cpus'],
      memory: vm['memory'],
      disk_size: vm['total_disk_size'],
      os: vm['operating_system'],
      os_distro: vm['operating_system_distro'],
      template: template,
      location: template.location,
      primary_ip_address: vm['ip_addresss'].try(:first),
      payment_type: :prepaid,
    }
    server.update_attributes! params
    server.state = ServerTasks.get_server_state(vm, server)
    server.save!
  end
  
  class << self
    def create_vapp(wizard)
      api = OnappBlanketAPI.new.connection wizard.user
      params = generate_vapp_params(wizard)
      result = api.post(:vapps, body: params).vapp
      Rails.logger.info result
      if result.id
        VCD.create(
          user: wizard.user,
          identifier: result.id,
          name: wizard.name,
          template: wizard.template,
          status: 'building'
        )
      end
    end

    def generate_vapp_params(wizard)
      {
        vapp: {
          name: wizard.name,
          vapp_template_id: wizard.template.identifier,
          vdc_id: ENV['VCD_ID'],
          network: ENV['VCD_NETWORK_ID'],
          virtual_machine_params: {
            wizard.template.vmid => {
              name: wizard.template.name,
              vcpu_per_vm: 1,
              core_per_socket: 1,
              memory: 1024,
              hard_disks: {
                'Hard disk 1' => {
                  storage_policy: 126,
                  disk_space: 10
                }
              }
            }
          }
        }
      }
    end
  end
end
