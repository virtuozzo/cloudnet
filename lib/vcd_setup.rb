class VCDSetup
  class << self
    def api
      OnappBlanketAPI.new.admin_connection
    end
    
    def import_templates
      html = open("#{ENV['ONAPP_CP']}/vapps/new",
        {
          http_basic_authentication: ['cloudnetvcd', ENV['VCDEMO_PASS']],
          ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
        }
      )
      doc = Nokogiri::HTML html
      options = doc.css '#vapp_vapp_template_id option'
      options.each do |template|
        id = template.attributes['value'].value
        Template.create!(
          location: 1,
          identifier: id,
          vmid: get_vmid id,
          name: template.content,
          os_type: 'vCD',
          onapp_os_distro: 'vCD',
          os_distro: 'vCD'
        )
      end
    end
    
    def get_vmid(id)
      details = api.get(
        "/vapp_templates/#{id}/hardware_customization",
        params: { vdc_id: ENV['VCD_ID'] }
      )
      details.indentifier
    end
  end
end
