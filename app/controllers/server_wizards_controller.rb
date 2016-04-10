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
    @packages = @wizard_object.packages
    return unless meets_minimum_server_requirements?
    send("step#{@wizard_object.current_step}".to_sym)
    set_event_name
  end

  def create
    process_server_wizard

    return unless meets_minimum_server_requirements?
    create_task = CreateServerTask.new(@wizard_object, current_user)
    @wizard_object.ip_addresses = 1
    @wizard_object.validation_reason = current_user.account.fraud_validation_reason(ip) if current_user
    
    unless @wizard_object.provisioner_role.blank?
      provisioner_template = @wizard_object.location.provisioner_templates.first
      @wizard_object.os_type = provisioner_template.os_type
      @wizard_object.template_id = provisioner_template.id
    else
      @wizard_object.provisioner_role = nil
    end

    if @wizard.save && create_task.process
      new_server = create_task.server
      new_server.create_activity :create, owner: current_user, params: { ip: ip, admin: real_admin_id }
      track_analytics_for_server(new_server)
      if new_server.validation_reason > 0
        NotifyUsersMailer.delay.notify_server_validation(current_user, [new_server])
        SupportTasks.new.perform(:notify_server_validation, current_user, [new_server]) rescue nil
        new_server.create_activity :validation, owner: current_user, params: { reason: new_server.validation_reason }
        log_risky_ip_addresses
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
  
  def log_risky_ip_addresses
    ips = []
    ips << request.remote_ip
    current_user.account.billing_cards.map(&:ip_address).each {|i| ips << i} unless current_user.account.billing_cards.blank?
    ips.push current_user.current_sign_in_ip, current_user.last_sign_in_ip
    ips.flatten.uniq.each do |ip_address|
      current_user.account.risky_ip_addresses.find_or_create_by(ip_address: ip_address)
    end
  end

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
      redirect_to servers_path, alert: 'You already have the maximum number of servers allowed for the beta'
      false
    elsif !@wizard_object.has_minimum_resources?
      redirect_to servers_path, alert: 'You do not have enough resources to create a new server'
      false
    elsif !current_user.confirmed?
      redirect_to servers_path, alert: 'Please confirm your email address before creating a server'
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
