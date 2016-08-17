class DestroyServerTask < BaseTask
  
  # NegativeBalanceProtection::Actions::DestroyAllServersConfirmed
  # may need update if you change the way servers are being destroyed
  def initialize(server, user, user_ip)
    super
    @server = server
    @user   = user
    @ip     = user_ip
  end

  def process
    tasker  = ServerTasks.new
    account = @user.account

    begin
      tasker.perform(:destroy, @user.id, @server.id)
      @server.create_credit_note_for_time_remaining
      create_destroy_invoice
      @server.destroy_with_ip(@ip)
      charge_unpaid_invoices(account)
      create_sift_event
      @user.account.expire_wallet_balance
    rescue Faraday::Error::ClientError => e
      ErrorLogging.new.track_exception(e, extra: { current_user: @user, source: 'DestroyServerTask', faraday: e.response })
      errors.push 'Could not schedule destroy of server. Please try again later'
      return false
    rescue Exception => e
      ErrorLogging.new.track_exception(e, extra: { current_user: @user, source: 'DestroyServerTask' })
      errors.push 'Could not schedule destroy of server. Please try again later'
      return false
    end

    true
  end
  
  def create_destroy_invoice
    invoice = Invoice.generate_prepaid_invoice([@server], @user.account, 0, :destroy)
    invoice.save if invoice.pre_coupon_net_cost > 0
  end
  
  def charge_unpaid_invoices(account)
    unpaid = account.invoices.not_paid
    ChargeInvoicesTask.new(@user, unpaid).process unless unpaid.empty?
  end
  
  def create_sift_event
    CreateSiftEvent.perform_async("destroy_server", @server.sift_server_properties)
  rescue StandardError => e
    ErrorLogging.new.track_exception(e, extra: { user: @user.id, source: 'DestroyServerTask#create_sift_event' })
  end
end
