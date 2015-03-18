# Fetch the available datacentres and templates currently on the Federation
class UpdateFederationResources
  # GP coords [lat, long] for
  COORDS_FOR_DATACENTRES = {
    'Cloud.net Budget US Dallas Zone' => [32.7767, 96.7970]
  }

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
    virtualization.split(',').include? 'remote'
  end

  def loop_through_templates(datacentre)
    templates = datacentre['relations']
    templates.each do |template|
      upsert_template template, datacentre
    end
  end

  def upsert_datacentre(datacentre)
    Location.find_or_initialize(
      hv_group_id: datacentre['hypervisor_group_id']
    ).update_attributes(
      latitude: COORDS_FOR_DATACENTRES[datacentre['label']][0],
      longitude: COORDS_FOR_DATACENTRES[datacentre['label']][1],
      provider: datacentre['label'],
      country: ,
      city: ,
      memory:
      disk_size:
      cpu:
      hidden: false,
      price_memory: ,
      price_disk: ,
      price_cpu: ,
      price_bw: ,
      provider_link: ,
      network_limit:
      photo_ids: ,
      price_ip_address: ,
      budget_vps: ,
      inclusive_bandwidth: ,
      ssd_disks:
    )
  end

  def upsert_template(template, datacentre)
    details = template['image_template']
    Template.find_or_initialize(
    ).update_atributes(
      identifier: template['id'],
      location: datacentre['hypervisor_group_id'],
      name: details['label'],
      os_type: details['operating_system'],
      onapp_os_distro: details['operating_system_distro'],
      min_memory: details['min_memory_size'],
      min_disk: details['min_disk_size'],
      hourly_cost: template['price']
    )
  end
end
