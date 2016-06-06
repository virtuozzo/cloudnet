class UpdateSiftHistoryTask
  attr_reader :user, :account, :suspended
  
  def initialize(user, suspended)
    @user    = user
    @account = user.account
    @suspended = suspended
  end

  def process
    ## Send a $create_account event to Sift
    user.create_sift_account(true)
    
    ## Send key events
    send_key_events
    
    ## Send chargebacks
    send_chargebacks
    
    ## Label user if required
    send_label
  end
  
  def send_key_events
    # 1. Invoices / orders
    account.invoices.each do |invoice|
      invoice.create_sift_event
      
      # 2. Charges
      invoice.charges.each do |charge|
        charge.create_sift_event
      end
    end
    
    # 3. Credit notes
    account.credit_notes.each do |credit_note|
      credit_note.create_sift_event
    end
    
    # 4. Payment receipts
    account.payment_receipts.each do |payment_receipt|
      payment_receipt.create_sift_event
    end
  end
  
  def send_chargebacks
    @chargeback_activities = PublicActivity::Activity.where(owner_id: user.id, owner_type: "User", key: "user.chargeback")
    @chargeback_activities.each do |activity|
      payment_receipt = PaymentReceipt.with_deleted.find activity.parameters[:payment_receipt_id].to_i
      charge = Charge.where(source_type: 'PaymentReceipt', source_id: payment_receipt.id).first
      invoice_id = charge.try(:invoice_id)
      chargeback_properties = {
        "$user_id"            => account.user_id,
        "$transaction_id"     => payment_receipt.number,
        "$chargeback_state"   => DisputeHandlerTask.dispute_status(activity[:status]),
        "$chargeback_reason"  => DisputeHandlerTask.dispute_reason(activity[:reason]),
        "$time"               => activity.created_at.to_i
      }
      chargeback_properties.merge!("$order_id" => invoice_id) if invoice_id
      CreateSiftEvent.perform_async("$chargeback", chargeback_properties)
    end
  rescue StandardError => e
    ErrorLogging.new.track_exception(e, extra: { user: user.id, source: 'UpdateSiftHistoryTask#send_chargebacks' })
  end
  
  def send_label
    # 1. Check if user received chargebacks
    if !@chargeback_activities.empty?
      label_properties = SiftProperties.sift_label_properties true, ["$chargeback"], "Received chargeback", "payment_gateway"
      create_sift_label(label_properties)
      return
    end
    
    # 2. Check if servers destroyed from validation queue
    destroy_activities = PublicActivity::Activity.where(owner_id: user.id, owner_type: "User", key: "server.destroy")
    destroy_activity = destroy_activities.detect {|activity| !activity.parameters[:admin].nil? }
    if !destroy_activity.nil?
      server = Server.with_deleted.find destroy_activity.trackable_id
      reasons = case server.validation_reason
        when 2, 5; ["$duplicate_account"]
        when 4; ["$chargeback"]
      end
      description = Account::FraudValidator::VALIDATION_REASONS[server.validation_reason]
      admin_user = User.with_deleted.find(destroy_activity.parameters[:admin].to_i)
      label_properties = SiftProperties.sift_label_properties true, reasons, description, "manual_review", admin_user.email
      create_sift_label(label_properties)
      return
    end
    
    # 3. Check if user had all his servers destroyed for non-payment of invoices
    non_payment_activities = PublicActivity::Activity.where(owner_id: user.id, owner_type: "User", key: "user.destroy_all_servers")
    if !non_payment_activities.empty?
      label_properties = SiftProperties.sift_label_properties true, nil, "Balance checker: Unpaid invoices", "negative_balance_checker"
      create_sift_label(label_properties)
      return
    end
    
    #  4. Check if user is currently suspended or has ever been suspended in the past
    suspend_activity = PublicActivity::Activity.where(owner_id: user.id, owner_type: "User", key: "user.suspend").first
    if suspended or !suspend_activity.nil?
      admin_user = User.with_deleted.find suspend_activity.parameters[:admin].to_i if suspend_activity
      label_properties = SiftProperties.sift_label_properties true, nil, "Manually suspended", "manual_review", admin_user.try(:email)
      create_sift_label(label_properties)
      return
    end
  rescue StandardError => e
    ErrorLogging.new.track_exception(e, extra: { user: user.id, source: 'UpdateSiftHistoryTask#send_label' })
  end
  
  def create_sift_label(label_properties)
    SiftLabel.perform_async(:create, user.id.to_s, label_properties)
    LabelDevices.perform_async(user.id, "bad")
  end
end
