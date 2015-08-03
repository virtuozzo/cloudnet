class ServerWizardsController < ServerCommonController
  def new
    params = location_id_in_params? ? prepare_fake_params : params
    @wizard = ModelWizard.new(ServerWizard, user_session, params, :server_wizard).start
    @wizard_object = @wizard.object
    @wizard_object.user = current_user
    @wizard_object.current_step = 2 if location_id_in_params?
    return unless meets_minimum_server_requirements
    send("step#{@wizard_object.current_step}".to_sym)
  end

  def create
    process_server_wizard

    return unless meets_minimum_server_requirements

    vapp = false
    create_task =
    if @wizard.object.template.os_distro.scan(/vcd/i).length > 0
      vapp = true
      CreateVappTask.new(@wizard_object, current_user)
    else
      if @wizard_object.prepaid?
        CreateServerTask.new(@wizard_object, current_user)
      else
        CreatePaygServerTask.new(@wizard_object, current_user)
      end
    end

    if @wizard.save && create_task.process
      if vapp
        notice = 'vApp created successfully and will be deployed shortly'
        redirect_to '/', notice: notice
      else
        create_task.server.create_activity :create, owner: current_user, params: { ip: ip, admin: real_admin_id }
        track_analytics_for_server(create_task.server)
        notice = 'Server successfully created and will be booted shortly'
        redirect_to server_path(create_task.server), notice: notice
      end
    else
      @wizard_object.errors.add(:base, create_task.errors.join(', ')) if create_task.errors?
      send("step#{@wizard_object.current_step}".to_sym)
      render :new
    end
  end

  private

  def location_id_in_params?
    @location_id_param ||= begin
        return unless params['id']
        params['id'] unless Location.where(id: params['id'], hidden: false).empty?
      end
  end

  def prepare_fake_params
    {server_wizard:
      { memory: params[:mem].try(:to_number),
        cpus: params[:cpu].try(:to_number),
        disk_size: params[:disk].try(:to_number),
        location_id: params[:id].try(:to_number)
      }
    }
  end

  def meets_minimum_server_requirements
    if !@wizard_object.can_create_new_server?
      redirect_to servers_path, alert: 'You already have the maximum number of servers allowed for the beta'
      false
    elsif !@wizard_object.has_minimum_resources?
      redirect_to servers_path, alert: 'You do not have enough resources to create a new server'
      false
    else
      true
    end
  end

  def step1
    @locations = Location.all.where(hidden: false)
    @cloud_locations  = @locations.where(budget_vps: false)
    @budget_locations = @locations.where(budget_vps: true)

    Analytics.track(current_user, event: 'Server Wizard Step 1')
  end
end
