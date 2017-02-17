class IpAddressesController < ApplicationController
  before_action :set_server
  before_action :set_ip_address, except: [:index, :create]
  before_action :check_multiple_ip_support, except: [:index]
  
  def index
    respond_to do |format|
      format.html { 
        check_multiple_ip_support
        calculate_costs(@server.ip_addresses + 1)
        @ip_address = @server.server_ip_addresses.new 
        @ip_addresses_count = @server.server_ip_addresses.count
      }
      format.json { @ip_addresses = @server.server_ip_addresses.order(primary: :desc, id: :asc) }
    end
  end
  
  def create
    if @server.can_add_ips? && !@server.primary_network_interface.blank? && charge(@server.ip_addresses + 1)
      AssignIpAddress.perform_async(current_user.id, @server.id)
      Analytics.track(current_user, event: 'Added a new IP address')
      @server.ip_requested = @server.ip_requested + 1
      create_sift_event :create_ip_address, @server.sift_server_properties
      redirect_to server_ip_addresses_path(@server), notice: 'IP address has been requested and will be added shortly'
    else
      alert = @charge_error || 'Unable to add IP addresses to this server.'
      redirect_to server_ip_addresses_path(@server), alert: alert
    end
  rescue StandardError => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'IpAddresses#Create' })
    flash[:alert] = 'Could not create IP address. Please try again later'
    redirect_to server_ip_addresses_path(@server)
  end
  
  def destroy
    raise "Cannot remove Primary IP address" if @ip_address.primary?
    IpAddressTasks.new.perform(:remove_ip, current_user.id, @server.id, @ip_address.identifier)
    charge(@server.ip_addresses - 1)
    @ip_address.destroy!
    Analytics.track(current_user, event: 'Removed IP address')
    create_sift_event :destroy_ip_address, @server.sift_server_properties
    redirect_to server_ip_addresses_path(@server), notice: 'IP address has been removed'
  rescue StandardError => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'IpAddresses#Destroy' })
    flash[:alert] = 'Could not remove IP address. Please try again later'
    redirect_to server_ip_addresses_path(@server)
  end
  
  private
  
  def charge(ip_addresses)
    return true unless @server.ips_chargeable?
    old_server_specs = Server.new @server.as_json(methods: :addon_ids)
    server_hash = @server.attributes.slice(*ServerWizard::ATTRIBUTES.map(&:to_s))
    @edit_wizard = ServerWizard.new server_hash
    @edit_wizard.addon_ids = @server.addon_ids
    @edit_wizard.existing_server_id = @server.id
    @edit_wizard.card = current_user.account.billing_cards.first
    @edit_wizard.user = current_user
    @edit_wizard.ip_addresses = ip_addresses
    if @edit_wizard.enough_wallet_credit?
      @edit_wizard.edit_server(old_server_specs)
    else
      @charge_error = 'You do not have enough credits to add more IP addresses. Please top up your Wallet and try again.'
      return false
    end
  end
  
  def calculate_costs(ip_addresses)
    @new_server = ServerWizard.new @server.attributes.slice(*ServerWizard::ATTRIBUTES.map(&:to_s))
    @new_server.ip_addresses = ip_addresses
    
    @current_server = ServerWizard.new @server.attributes.slice(*ServerWizard::ATTRIBUTES.map(&:to_s))
    @current_server.ip_addresses = @server.ip_addresses

    coupon_percentage = current_user.account.coupon.present? ? current_user.account.coupon.percentage_decimal : 0
    credit = @server.generate_credit_item(CreditNote.hours_till_next_invoice(current_user.account))[:net_cost] * (1 - coupon_percentage)    
    monthly = @new_server.monthly_cost
    current_monthly = @current_server.monthly_cost
    today = @new_server.cost_for_hours Invoice.hours_till_next_invoice(current_user.account)
    billable_today = today - credit
    billable_monthly = monthly - current_monthly
    @costs = {
      monthly:                  billable_monthly,
      monthly_with_vat:         Invoice.with_tax(billable_monthly),
      today:                    billable_today,
      today_with_vat:           Invoice.with_tax(billable_today)
    }
    @coupon_multiplier = (1 - coupon_percentage)
  end

  def set_server
    @server = current_user.servers.find(params[:server_id])
  end
  
  def set_ip_address
    @ip_address = @server.server_ip_addresses.find(params[:id])
  end
  
  def check_multiple_ip_support
    redirect_to_dashboard unless @server.supports_multiple_ips?
  end
end
