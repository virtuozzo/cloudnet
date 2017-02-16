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
      next unless on_federation? datacentre
      upsert_datacentre datacentre
      loop_through_templates datacentre
    end
  end

  def on_federation?(datacentre)
    return false unless datacentre['hypervisor_group_id']
    # The clue is the 'remote' tag on a template, so peek at the first template
    first_template = datacentre['relations'].first
    virtualization = first_template['image_template']['virtualization']
    return false unless virtualization
    virtualization.include? 'remote'
  end

  def loop_through_templates(datacentre)
    templates = datacentre['relations']
    templates.each do |template|
      upsert_template template, datacentre
    end
  end

  def upsert_datacentre(datacentre)
    Location.where(
      hv_group_id: datacentre['hypervisor_group_id']
    ).first_or_initialize(
      provider: datacentre['label']
    ).save(validate: false)
  end

  def upsert_template(template, datacentre)
    details = template['image_template']
    location = Location.find_by hv_group_id: datacentre['hypervisor_group_id']
    Template.where(
      identifier: details['id'].to_s,
    ).first_or_initialize(
      location: location,
      name: details['label'],
      os_type: details['operating_system'],
      onapp_os_distro: details['operating_system_distro'],
      min_memory: details['min_memory_size'],
      min_disk: details['min_disk_size'],
      hourly_cost: template['price'],
      os_distro: details['operating_system'].to_s + "-" + details['operating_system_distro']
    ).save(validate: false)
  end
end
