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
    
    # Log $order_status and $chargeback events with Sift Science
    create_sift_events
    
    # Label the user as bad at Sift Science
    create_sift_label
    
    # Label all devices associated with this user as 'bad'
    label_devices
    
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
    begin
      ServerTasks.new.perform(:shutdown, server.user_id, server.id)
    rescue StandardError => e
      ErrorLogging.new.track_exception(e, extra: { server: server.id, source: 'DisputeHandlerTask#block_server' })
    ensure
      server.create_activity :shutdown, owner: server.user
      server.update!(validation_reason: 4)
      server.create_activity :validation, owner: server.user, params: { reason: server.validation_reason }
    end
  end
  
  def self.dispute_status(status)
    case status
    when "warning_needs_response", "needs_response"
      "$received"
    when "warning_under_review", "under_review"
      "$disputed"
    when "lost"
      "$lost"
    when "won"
      "$won"
    else
      "$received"
    end
  end
  
  def self.dispute_reason(reason)
    case reason
    when "duplicate"
      "$duplicate"
    when "fraudulent"
      "$fraud"
    when "product_not_received"
      "$product_not_received"
    else
      "$other"
    end
  end
  
  def create_sift_events
    charge = Charge.where(source_type: 'PaymentReceipt', source_id: @payment_receipt.id).first
    invoice_id = charge.try(:invoice_id)
    chargeback_properties = {
      "$user_id"            => @account.user_id,
      "$transaction_id"     => @payment_receipt.number,
      "$chargeback_state"   => self.class.dispute_status(@dispute["status"]),
      "$chargeback_reason"  => self.class.dispute_reason(@dispute["reason"])
    }
    chargeback_properties.merge!("$order_id" => invoice_id) if invoice_id
    
    order_status_properties = {
      "$user_id"            => @account.user_id,
      "$order_id"           => invoice_id,
      "$source"             => "$automated",
      "$order_status"       => "$held",
      "$description"        => "Chargeback"
    }
    
    CreateSiftEvent.perform_async("$chargeback", chargeback_properties)
    CreateSiftEvent.perform_async("$order_status", order_status_properties) if invoice_id
  rescue StandardError => e
    ErrorLogging.new.track_exception(e, extra: { user: @account.user.id, source: 'DisputeHandlerTask#create_sift_events' })
  end
  
  def create_sift_label
    label_properties = SiftProperties.sift_label_properties true, ["$chargeback"], "Received chargeback", "payment_gateway"
    SiftLabel.perform_async(:create, @account.user_id.to_s, label_properties)
  end
  
  def label_devices
    LabelDevices.perform_async(@account.user_id, "bad")
  end
  
end
