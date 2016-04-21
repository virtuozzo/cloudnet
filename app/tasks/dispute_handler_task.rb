class DisputeHandlerTask < BaseTask
  
  def initialize(dispute)
    super
    @dispute = dispute
    @payment_receipt = PaymentReceipt.find_by_reference @dispute["charge"]
    @account = @payment_receipt.account unless @payment_receipt.blank?
  end

  def process
    return false if @account.blank?
    
    # Log chargeback activity
    @account.user.create_activity(:chargeback, owner: @account.user, params: { amount: @dispute['amount'], currency: @dispute['currency'], reason: @dispute['reason'], status: @dispute['status'], payment_receipt_id: @payment_receipt.id })
    
    # Shutdown and put the servers under validation, eventually blocking the servers on next refresh
    @account.user.servers.map { |server| block_server(server) }
    
    # Notify user and support
    unless @account.user.servers.blank?
      NotifyUsersMailer.notify_server_validation(@account.user, @account.user.servers).deliver_now
      SupportTasks.new.perform(:notify_server_validation, @account.user, @account.user.servers) rescue nil
    end
    
    # Log the IP addresses associated with the account to risky ip addresses list for future use
    @account.log_risky_ip_addresses
    
    # Log the billing cards associated with the account to risky cards list for future use
    @account.log_risky_cards
    
    # Retrieve and update dispute object at Stripe with payment receipt and account info
    update_dispute
    
    true
  end

  private

  def update_dispute
    stripe_dispute = Payments.new.get_dispute @dispute["id"]
    stripe_dispute.metadata = {payment_receipt_id: @payment_receipt.id, payment_receipt_ref: @payment_receipt.receipt_number, account: @payment_receipt.account_id}
    stripe_dispute.save
  end
  
  def block_server(server)
    return if server.validation_reason > 0
    ServerTasks.new.perform(:shutdown, server.user_id, server.id)
    server.create_activity :shutdown, owner: server.user
    server.update!(validation_reason: 4)
    server.create_activity :validation, owner: server.user, params: { reason: server.validation_reason }
  end
end
