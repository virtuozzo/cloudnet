# Fetch the available datacentres and templates currently on the Federation
class UpdateFederationResources
  def self.run
    new.run
  end

  def run
    squall = Squall::Template.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
    @store = squall.template_store
    loop_through_datacentres
  end

  def loop_through_datacentres
    @store.each do |datacentre|
      loop_through_templates datacentre
    end
  end

  def loop_through_templates(datacentre)
    templates = datacentre['relations']
    templates.each do |template|
      upsert_template template
    end
  end

  def upsert_template(template)
    details = template['image_template']
    Template.find_or_create_by!(identifier: template['template_id'].to_s) do |t|
      t.location = Location.find(2)
      t.name = details['label']
      t.os_type = details['operating_system']
      t.onapp_os_distro = details['operating_system_distro']
      t.os_distro = 'vCenter'
    end
  end
end
