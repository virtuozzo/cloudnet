class ServerWizardsController < ServerCommonController
  skip_before_action :authenticate_user!, only: [:new, :create]
  layout proc { "public" unless user_signed_in? }

  def new
    params = location_id_in_params? ? prepare_fake_params : params

    @wizard = ModelWizard.new(ServerWizard, session, params, :server_wizard).start
    @wizard_object = @wizard.object
    @wizard_object.user = current_user
    @wizard_object.current_step = 2 #if location_id_in_params?
    @wizard_object.ip_addresses = 1
    @wizard_object.addon_ids = []
    @wizard_object.ssh_key_ids = []
    @packages = @wizard_object.packages
    @keys = current_user.keys if current_user
    @key = Key.new
    return unless meets_minimum_server_requirements?
    send("step#{@wizard_object.current_step}".to_sym)
    set_event_name
  end

  def create    
    if params[:server_wizard] && params[:server_wizard][:current_step] == "2"
      session[:server_wizard_params][:addon_ids] = [] if params[:server_wizard][:addon_ids].blank?
      session[:server_wizard_params][:ssh_key_ids] = [] if params[:server_wizard][:ssh_key_ids].blank?
    end
    
    process_server_wizard

    return unless meets_minimum_server_requirements?
    create_task = CreateServerTask.new(@wizard_object, current_user)
    @wizard_object.ip_addresses = 1
    @wizard_object.validation_reason = current_user.account.fraud_validation_reason(ip) if current_user
    @keys = current_user.keys if current_user
    @key = Key.new

    unless @wizard_object.provisioner_role.blank?
      provisioner_template = @wizard_object.location.provisioner_templates.first
      @wizard_object.os_type = provisioner_template.os_type
      @wizard_object.template_id = provisioner_template.id
    else
      @wizard_object.provisioner_role = nil
    end

    if @wizard.save && create_task.process
      new_server = create_task.server
      new_server.create_activity :create, owner: current_user, params: { ip: ip, admin: real_admin_id, provisioned: new_server.provisioner_role}
      track_analytics_for_server(new_server)
      if new_server.validation_reason > 0
        NotifyUsersMailer.delay.notify_server_validation(current_user, [new_server])
        SupportTasks.new.perform(:notify_server_validation, current_user, [new_server]) rescue nil
        new_server.create_activity :validation, owner: current_user, params: { reason: new_server.validation_reason }
        current_user.account.log_risky_ip_addresses(ip)
        current_user.account.log_risky_cards
        notice = 'Server successfully created but has been placed under validation. A support ticket has been created for you. A support team agent will review and reply to you shortly.'
      else
        notice = 'Server successfully created and will be booted shortly'
      end
      redirect_to server_path(new_server), notice: notice
    else
      @packages = @wizard_object.packages
      @wizard_object.errors.add(:base, create_task.errors.join(', ')) if create_task.errors?
      force_authentication! if step3_non_logged?
      send("step#{@wizard_object.current_step}".to_sym)
      set_event_name
      render :new
    end
  end

  def payment_step
    create
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

  def search_params
    p = session[:server_wizard_params]
    {mem: p[:memory], cpu: p[:cpus], disc: p[:disk_size]}
  end

  def step3_non_logged?
    !current_user and @wizard_object.step3? and @wizard_object.no_errors?
  end

  def force_authentication!
    session[:user_return_to] = servers_create_payment_step_path
    authenticate_user!
  end

  def meets_minimum_server_requirements?
    return true unless current_user
    if !@wizard_object.can_create_new_server?
      redirect_to servers_path, alert: 'You already have the maximum number of servers allowed. Please contact support to increase the limit.'
      false
    elsif !@wizard_object.has_minimum_resources?
      redirect_to servers_path, alert: 'You do not have enough resources to create a new server. Please contact support to increase the limit.'
      false
    else
      true
    end
  end

  def step1
    @regions = Region.active
    @locations = Location.all.where(hidden: false)
    @cloud_locations  = @locations.where(budget_vps: false)
    @budget_locations = @locations.where(budget_vps: true)

    Analytics.track(current_user, event: 'Server Wizard Step 1')
  end

  def set_event_name
    @event_name = case @wizard_object.current_step
      when 1 then "New Server - Should not be here"
      when 2 then "New Server - Options"
      when 3 then "New Server - Billing Options"
    end
  end
end
