class ServersController < ServerCommonController
  before_action :set_server, except: [:index, :new, :create]

  def index
    @servers = current_user.servers.order(id: :asc)
  end

  def show
    calculate_server_costs
    cpu_usages
    network_usages
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
        current_step: 1
      }
    end
    process_server_wizard
    @wizard_object.location_id = @server.location_id
    @wizard_object.submission_path = edit_server_path @server
    @wizard.save
    # Prob not the right way to check, but it's unclear how else to do it
    if params[:server_wizard] && params[:server_wizard][:payment_type]
      schedule_edit
      flash[:info] = 'Server scheduled for updating'
      redirect_to server_path(@server)
      return
    elsif @wizard_object.current_step == 3
      step3
    else
      step2
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
  end

  def console
    @console = ServerConsole.new(@server, current_user).process
    log_activity :console
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
    redirect_to :back, notice: 'Server has been scheduled for a reboot.'
  rescue Faraday::Error::ClientError
    flash[:warning] = 'Could not schedule reboot server. Please try again later'
    redirect_to :back
  end

  def shut_down
    schedule_task(:shutdown, @server)
    log_activity :shutdown
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
    destroy = if @server.prepaid?
                DestroyServerTask.new(@server, current_user, request.remote_ip)
              else
                DestroyPaygServerTask.new(@server, current_user, request.remote_ip)
    end

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
    credit = @server.generate_credit_item(CreditNote.hours_till_next_invoice(current_user.account))
    net_cost = credit[:net_cost]
    net_cost = 0 if @server.in_beta?
    render json: { credit: net_cost }
  end
  
  def rebuild_network
    raise "Server is not built" unless @server.built?
    RebuildNetwork.new(@server, current_user).process
    Analytics.track(current_user, event: 'Rebuilt network')
    redirect_to :back, notice: 'Network rebuild has been scheduled'
  rescue Exception => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'Servers#rebuild_network' })
    flash.now[:alert] = 'Could not rebuild network. Please try again later'
    redirect_to :back
  end

  private

  def calculate_server_costs
    monthly = @server.monthly_cost
    hourly  = @server.hourly_cost

    @server_costs = {
      monthly:          monthly * (1 - coupon_percentage),
      monthly_with_vat: Invoice.with_tax(monthly) * (1 - coupon_percentage),
      hourly:           hourly * (1 - coupon_percentage),
      hourly_with_vat:  Invoice.with_tax(hourly) * (1 - coupon_percentage)
    }
  end

  def coupon_percentage
    coupon = current_user.account.coupon
    coupon.present? ? coupon.percentage_decimal : 0
  end

  def schedule_task(task, server, monitor = true)
    ServerTasks.new.perform(task, current_user.id, server.id)
    MonitorServer.perform_in(MonitorServer::POLL_INTERVAL.seconds, server.id, current_user.id) if monitor
  end

  def set_server
    @server = current_user.servers.find(params[:id])
  end

  def log_activity(activity)
    @server.create_activity activity, owner: current_user, params: { ip: ip, admin: real_admin_id }
  end

  def schedule_edit
    # as_json() effectively serializes and bypasses any pass-by-ref prolems
    old_server_specs = Server.new @server.as_json
    @server.edit(session[:server_wizard_params])
    # Bit of an ugly hack to piggy back off the server wizard. We're pretending as if the current
    # server with new specs is being asked to be built from scratch - that's what the wizard was
    # orginally designed to do, ie; building servers from scratch.
    server_hash = @server.attributes.slice(*ServerWizard::ATTRIBUTES.map(&:to_s))
    wizard = ServerWizard.new server_hash
    wizard.existing_server_id = @server.id
    wizard.card = current_user.account.billing_cards.first
    wizard.user = current_user
    # Send the old server so that a credit note can be issued for it
    wizard.edit_server(old_server_specs)
    log_activity :edit
  end
end
