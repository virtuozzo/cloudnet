class DestroyServerTask < BaseTask
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
      @server.destroy_with_ip(@ip)
      create_destroy_invoice
      charge_unpaid_invoices(account)
      UpdateAgilecrmContact.perform_async(@user.id, nil, ['server-deleted'])
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
end
