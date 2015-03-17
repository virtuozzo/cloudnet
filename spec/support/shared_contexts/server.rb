shared_context :with_server do
  include_context :with_user

  before :each do
    # Temporary measure to automatically get location/template data. Hopefully we can find a way
    # of autopopulating the DB with this data
    # It's stored in a file because we Don't want VCR to record the 400k response body :/
    def find_ubuntu_template_on_federation
      locations_path = "#{Rails.root}/locations.json"
      fail 'Please run `rake cache_locations`' unless File.exist? locations_path
      store = JSON.parse File.read locations_path

      store.each do |item|
        next unless item['label'] =~ /Cloud.net Budget UK London Zone/
        hypervisor_group_id = item['hypervisor_group_id']
        templates = item['relations']
        templates.each do |template|
          details = template['image_template']
          virtualization = details['virtualization']
          next unless virtualization
          on_federation = virtualization.split(',').include? 'remote'
          is_ubuntu14 = details['label'].include? 'Ubuntu 14'
          return [hypervisor_group_id, template['template_id']] if on_federation && is_ubuntu14
        end
      end
      fail "Couldn't find an Ubuntu 14 image on your version of the Federation"
    end

    hypervisor_group_id, template_id = find_ubuntu_template_on_federation

    location = FactoryGirl.create :location, hv_group_id: hypervisor_group_id
    template = FactoryGirl.create(
      :template,
      location: location,
      identifier: template_id
    )

    # Simulate stepping through the Server creation wizard
    @wizard = FactoryGirl.build(
      :server_wizard,
      user: @user,
      cpus: 1,
      location: location,
      memory: 512,
      card_id: @user.account.billing_cards.first
    )
    @wizard.template = template

    # Don't need to monitor the server during tests. We can manually request server updates
    allow(MonitorServer).to receive(:perform_async)

    # Creates a server on both the Federation and cloud.net
    create_server_task = CreateServerTask.new(@wizard, @user)
    create_server_task.process
    @server = create_server_task.server

    # An instance of the server tasker to speak to the Federation about our new server
    @server_task = ServerTasks.new

    @server.wait_until_ready
  end
end
