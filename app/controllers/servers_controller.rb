class ServersController < ServerCommonController
  before_action :set_server, except: [:index, :new, :create]
  before_action :check_server_state, only: [:rebuild_network, :reset_root_password]
  class EditInProgressError < StandardError; end

  def index
    @servers = current_user.servers.order(id: :asc)
  end

  def show
    respond_to do |format|
      format.html {
        calculate_server_costs
        cpu_usages
        network_usages
      }
      format.json
    end
  end

  def install_notes
    notes = DockerProvisionerTasks.new.status(@server.provisioner_job_id).body rescue nil
    notes_json = JSON.parse(notes)['install_notes'] unless notes.nil?
    render partial: 'show_install_notes', layout: false, locals: {notes_json: notes_json}
  end

  def edit
    @server = Server.find(params[:id])
    # When first visiting the edit wizard reset the user session
    session.delete :server_wizard_params if request.method == 'GET'
    unless session.key? :server_wizard_params
      session[:server_wizard_params] = {
        memory: @server.memory,
        cpus: @server.cpus,
        disk_size: @server.disk_size,
        provisioner_role: @server.provisioner_role,
        current_step: 1,
        addon_ids: @server.addons.pluck(:id)
      }
    end
    if params[:server_wizard] && params[:server_wizard][:current_step] == "2"
      session[:server_wizard_params][:addon_ids] = [] if params[:server_wizard][:addon_ids].blank?
    end
    process_server_wizard
    @wizard_object.location_id = @server.location_id
    @wizard_object.submission_path = edit_server_path @server
    @wizard_object.existing_server_id = @server.id
    @wizard_object.ip_addresses = @server.ip_addresses
    @packages = @wizard_object.packages
    
    if @server.no_refresh == false && @wizard.save
      actions = ServerSupportActions.new(current_user)
      old_server_specs = Server.new @server.as_json(methods: :addon_ids)
      edit_wizard = actions.prepare_edit(@server, session[:server_wizard_params])
      edit_wizard.set_old_server_specs(old_server_specs)
      actions.update_edited_server(@server, session[:server_wizard_params], edit_wizard)
      result = actions.schedule_edit(edit_wizard, old_server_specs)
      @server.process_addons if edit_wizard.addons_changed?
      if result.build_errors.length == 0
        log_activity :edit, old_specs: old_server_specs
        flash[:info] = 'Server scheduled for update'
        redirect_to server_path(@server)
        return
      else
        @wizard_object.errors.add(:base, result.build_errors.join(', '))
        step3
      end
    elsif @wizard_object.current_step == 3
      flash.now[:warning] = 'Please top up your Wallet to upgrade your server'
      step3
    else
      raise EditInProgressError if @server.no_refresh
      step2
      #FIXME: Not allowing to rebuild into Windows until onapp core team fix the problem
      @templates.reject! {|k,v| k.split("-")[0] == "windows"}
    end
    render 'server_wizards/edit'

  rescue Faraday::Error::ClientError => e
    ErrorLogging.new.track_exception(
      e,
      extra: {
        current_user: current_user,
        source: 'Server#Edit',
        faraday: e.response
      }
    )
    flash[:warning] = 'Could not schedule update of server. Please try again later'
    redirect_to :back

  rescue EditInProgressError
    flash[:warning] = "Server edit in progress. Wait until status is 'on'"
    redirect_to @server
  end

  def console
    @console = ServerConsole.new(@server, current_user).process
    log_activity :console
    create_sift_event :console_access, @server.sift_server_properties
  rescue Faraday::Error::ClientError => e
    ErrorLogging.new.track_exception(
      e,
      extra: {
        current_user: current_user,
        source: 'Server#Console',
        faraday: e.response
      }
    )
    flash[:warning] = 'Could not request server console. Please try again later'
    redirect_to servers_path(@server)
  end

  def reboot
    schedule_task(:reboot, @server)
    log_activity :reboot
    create_sift_event :reboot_server, @server.sift_server_properties
    redirect_to :back, notice: 'Server has been scheduled for a reboot.'
  rescue Faraday::Error::ClientError
    flash[:warning] = 'Could not schedule reboot server. Please try again later'
    redirect_to :back
  end

  def shut_down
    schedule_task(:shutdown, @server)
    log_activity :shutdown
    create_sift_event :shutdown_server, @server.sift_server_properties
    redirect_to :back, notice: 'Server has been scheduled for shut down.'
  rescue Faraday::Error::ClientError => e
    ErrorLogging.new.track_exception(
      e,
      extra: {
        current_user: current_user,
        source: 'Server#ShutDown',
        faraday: e.response
      }
    )
    flash[:warning] = 'Could not schedule shutdown server. Please try again later'
    redirect_to :back
  end

  def start_up
    schedule_task(:startup, @server)
    log_activity :startup
    create_sift_event :startup_server, @server.sift_server_properties
    redirect_to :back, notice: 'Server has been scheduled for start up.'
  rescue Faraday::Error::ClientError => e
    ErrorLogging.new.track_exception(
      e,
      extra: {
        current_user: current_user,
        source: 'Server#StartUp',
        faraday: e.response
      }
    )
    flash[:warning] = 'Could not schedule starting up of server. Please try again later'
    redirect_to :back
  end

  def events
    @events = @server.server_events.order('transaction_created DESC')
  end

  def cpu_usages
    @cpu_usages = ServerUsage.cpu_usages(@server)
  end

  def network_usages
    @network_usages = ServerUsage.network_usages(@server)
  end

  def destroy
    destroy = DestroyServerTask.new(@server, current_user, request.remote_ip)

    if destroy.process && destroy.success?
      log_activity :destroy
      redirect_to servers_path, notice: "Server '#{@server.name}' has been scheduled for deletion."
    else
      redirect_to servers_path, flash: { warning: destroy.errors.join(', ') }
    end

    Analytics.track(
      current_user,
      event: 'Destroyed Server',
      properties: {
        server: @server.to_s,
        specs: "#{@server.memory}MB RAM, #{@server.disk_size}GB Disk, #{@server.cpus} Cores"
      }
    )
  end

  def calculate_credit
    @server.refresh_usage rescue nil # always prepare data
    credit = @server.generate_credit_item(CreditNote.hours_till_next_invoice(current_user.account))
    paid_bandwidth = Billing::BillingBandwidth.new(@server).bandwidth_usage
    badwidth_price = @server.location.price_bw
    bandwidth_cost = paid_bandwidth[:billable] * badwidth_price
    net_cost = credit[:net_cost]
    net_cost = 0 if @server.in_beta?
    render json: { credit: net_cost, bandwidth: bandwidth_cost }
  end

  def rebuild_network
    RebuildNetwork.new(@server, current_user).process
    Analytics.track(current_user, event: 'Rebuilt network')
    redirect_to :back, notice: 'Network rebuild has been scheduled'
  rescue Exception => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'Servers#rebuild_network' })
    flash[:alert] = 'Could not rebuild network. Please try again later'
    redirect_to :back
  end

  def reset_root_password
    raise "Location does not support root password reset" unless @server.supports_root_password_reset?
    ResetRootPassword.new(@server, current_user).process
    Analytics.track(current_user, event: 'Reset root password')
    redirect_to :back, notice: 'Password has been reset'
  rescue Exception => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'Servers#reset_root_password' })
    flash[:alert] = 'Could not reset root password. Please try again later'
    redirect_to :back
  end

  private

  def check_server_state
    raise "Server is not built" if @server.state != :on && @server.state != :off
  end

  def calculate_server_costs
    monthly = @server.monthly_cost
    hourly  = @server.hourly_cost
    coupon_per = coupon_percentage

    @server_costs = {
      monthly:          monthly * (1 - coupon_per),
      monthly_with_vat: Invoice.with_tax(monthly) * (1 - coupon_per),
      hourly:           hourly * (1 - coupon_per),
      hourly_with_vat:  Invoice.with_tax(hourly) * (1 - coupon_per)
    }
  end

  def coupon_percentage
    coupon = current_user.account.coupon
    coupon.present? ? coupon.percentage_decimal : 0
  end

  # delegate, so api calls use the same code
  def schedule_task(task, server, monitor = true)
    ServerSupportActions.new(current_user).schedule_task(task, server.id, monitor)
  end

  def set_server
    @server = current_user.servers.find(params[:id])
  end

  def log_activity(activity, old_specs: nil)
    @server.create_activity activity, owner: current_user,
      params: {
        ip: ip,
        admin: real_admin_id,
        old_disk_size: old_specs.try(:disk_size),
        old_memory: old_specs.try(:memory),
        old_cpus: old_specs.try(:cpus),
        old_name: old_specs.try(:name),
        old_distro: old_specs.try(:template).try(:name),
        new_disk_size: @server.disk_size,
        new_memory: @server.memory,
        new_cpus: @server.cpus,
        new_name: @server.name,
        new_distro: @server.template.name
      }
  end
end
