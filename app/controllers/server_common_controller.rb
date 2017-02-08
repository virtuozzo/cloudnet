# Shared by the Server and ServerWizard controllers
class ServerCommonController < ApplicationController

  # When the Server Wizard is setup at a step after step 1
  def process_server_wizard
    @wizard = ModelWizard.new(ServerWizard, session, params, :server_wizard).process
    @wizard_object = @wizard.object
    @wizard_object.user = current_user
  end

  def location_packages
    @location = Location.find(params[:location_id])
    @packages = Package.where(location_id: params[:location_id])
    render 'location_packages', layout: false
  end

  def prepaid_server_cost
    process_server_wizard
    calculate_costs

    render partial: 'server_wizards/steps/partials/prepaid_confirmation_costs',
           locals: { costs: @costs, coupon_multiplier: @coupon_multiplier }
  end

  def payg_server_cost
    process_server_wizard
    calculate_costs

    render partial: 'server_wizards/steps/partials/payg_confirmation_costs',
           locals: { costs: @payg_costs, coupon_multiplier: @coupon_multiplier }
  end

  def payg
    server = Server.find(params[:id]) if params[:id]
    process_server_wizard
    if server
      @wizard_object.location_id = server.location_id
      @wizard_object.template_id = server.template.id
      @wizard_object.existing_server_id = server.id
    end
    render partial: 'billing/payg_details', locals: { payg: payg_details, wizard: @wizard_object }
  end

  private

  def step2
    @regions = Region.active
    @locations = Location.all.where(hidden: false)
    @templates = Location.find(@wizard_object.location_id).templates.where(hidden: false).where.not(os_distro: 'docker').group_by { |t| "#{t.os_type}-#{t.os_distro}" } unless @wizard_object.location_id.blank?
    Analytics.track(current_user, event_details_step2, anonymous_id, request)
  end

  def event_details_step2
    {event: 'New Server - Options',
      properties: {
        location: @wizard_object.location.to_s
      }.merge(UtmTracker.extract_properties(params))
    }
  end

  def step3
    calculate_costs

    Analytics.track(
      current_user,
      event: 'New Server - Billing Options',
      properties: {
        location: @wizard_object.location.to_s,
        template: @wizard_object.template.to_s,
        server: "#{@wizard_object.memory}MB RAM, #{@wizard_object.disk_size}GB Disk, #{@wizard_object.cpus} Cores"
      }
    )
  end

  def calculate_costs
    @account = current_user.account
    @cards   = @account.billing_cards.processable

    hourly = @wizard_object.hourly_cost
    monthly = @wizard_object.monthly_cost
    today   = @wizard_object.cost_for_hours Invoice.hours_till_next_invoice(current_user.account)

    @costs = {
      monthly:          monthly,
      monthly_with_vat: Invoice.with_tax(monthly),
      today:            today,
      today_with_vat:   Invoice.with_tax(today)
    }

    @payg_costs = {
      hourly:          hourly,
      hourly_with_vat: Invoice.with_tax(hourly)
    }

    @coupon_multiplier = (1 - coupon_percentage)
    @payg = payg_details
  end

  def coupon_percentage
    coupon = current_user.account.coupon
    if coupon.present? then coupon.percentage_decimal else 0 end
  end

  def payg_details
  end

  def track_analytics_for_server(server)
    role = server.provisioner_role
    postfix = role ? 'Provisioned' : 'Created Server'
    Analytics.track(
      current_user,
      event: "New Server - #{postfix}",
      properties: {
        location: @wizard_object.location.to_s,
        template: @wizard_object.template.to_s,
        server: "#{server.memory}MB RAM, #{server.disk_size}GB Disk, #{server.cpus} Cores",
        provisioned: role
      }
    )
  end

  def wizard_params
    params.require(:server_wizard).permit(:location_id, :os_distro_id, :template_id, :memory, :cpus, :disk_size, :bandwidth, :hostname, :name, :card_id, :ip_addresses, :provisioner_role, :addon_ids, :ssh_key_ids)
  end
end
