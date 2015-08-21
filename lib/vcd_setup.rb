# Get vCD env setup
class VCDSetup
  class << self
    def api
      OnappBlanketAPI.new.admin_connection
    end

    def import_templates
      if Template.count > 1
        raise "Aborting. There are already installed templates"
      end
      html = open(
        "#{ENV['ONAPP_CP']}/vapps/new",
        http_basic_authentication: [ENV['ONAPP_USER'], "#{ENV['ONAPP_PASS']}"],
        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
      )
      doc = Nokogiri::HTML html
      options = doc.css '#vapp_vapp_template_id option'
      options.each do |template|
        id = template.attributes['value'].value
        Template.create!(
          location: Location.find(1),
          identifier: id,
          vmid: get_vmid(id),
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
        params: { vdc_id: ENV['VDC_ID'] }
      )
      details.identifier
    end
  end
end
