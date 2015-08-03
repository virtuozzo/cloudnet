# A VMWare vApp
class VCD < ActiveRecord::Base
  class << self
    def create_vapp(wizard)
      api = OnappBlanketAPI.new.connection wizard.user
      params = generate_vapp_params(wizard)
      result = api.post(:vapps, body: params)
      Rails.logger.info result
    end

    def generate_vapp_params(wizard)
      {
        vapp: {
          name: wizard.name,
          vapp_template_id: wizard.template.identifier,
          vdc_id: 72,
          network: 359,
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
