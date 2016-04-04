class LocationTasks < BaseTasks
  def perform(action, location_id, *args)
    location = Location.find(location_id)
    run_task(action, location, *args)
  end

  def update_location(location)
    squall = Squall::Hypervisor.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
    hypervisors = squall.list.select { |hv| hv['hypervisor_group_id'] == location.hv_group_id }

    free_resources = { memory: 0, storage: 0, cpu: 0 }
    hypervisors.each do |hv|
      # For now, we are basing it solely on memory max
      # TODO: a more sophisticated algorithm
      next if hv['free_memory'] <= free_resources[:memory]

      storage = 0
      hv['free_disk_space'].each { |_k, v| storage = v if v > storage }

      free_resources = { memory: hv['free_memory'], storage: storage, cpu: hv['cpus'] }
    end

    location.update(
      memory: free_resources[:memory],
      disk_size: free_resources[:storage],
      cpu: free_resources[:cpu]
    )
  end

  # Automatically gets all the templates associated with a location/hyperisor on Onapp.
  # Saves having to manually add them.
  def update_templates(location)
    squall = Squall::Template.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
    store = squall.template_store.select { |t| t['hypervisor_group_id'] == location.hv_group_id }
    fail Exception, 'Could not find valid templates for this hypervisor group' if store.size == 0

    templates = store.first['relations']
    templates.each do |template|
      if Template.where(identifier: template['template_id'].to_s, location: location).count == 0
        image_template = template['image_template']
        os_distro = Template.distro_name(image_template['operating_system_distro'], image_template['label'], image_template['operating_system'])

        Template.create(
          identifier:   template["template_id"].to_s,
          name:         image_template["label"],
          location:     location,
          os_type:      image_template['operating_system'],
          os_distro:    os_distro,
          onapp_os_distro: image_template['operating_system_distro'],
          min_disk:     image_template['min_disk_size'],
          min_memory:   image_template['min_memory_size']
        )
      end
    end
  end

  def allowable_methods
    super + [:update_location, :update_templates]
  end
end
