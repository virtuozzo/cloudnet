class PaygTopupCardTask < BaseTask
  def initialize(account, usd_amount, ip = nil)
    @usd_amount = usd_amount.to_f
    @amount     = (@usd_amount * Payg::CENTS_IN_DOLLAR).to_i
    @account    = account
    @user       = account.user
    @card       = @account.primary_billing_card
    @remote_ip  = ip
  end

  def process
    unless @account.fraud_safe?(@remote_ip)
      errors << 'Restricted account. Please contact support.'
      return false
    end
    
    unless @account.valid_top_up_amounts.include?(@usd_amount.to_i)
      errors << 'Invalid top up amount'
      return false
    end

    unless @card.present?
      errors << 'You do not have a billing card associated with your account.'
      return false
    end

    begin
      charge = Payments.new.auth_charge(@account.gateway_id, @card.processor_token, @amount)
      @account.create_activity :auth_charge, owner: @user, params: { card: @card.id, amount: @amount, charge_id: charge[:charge_id] }
      Payments.new.capture_charge(charge[:charge_id], "#{ENV['BRAND_NAME']} Top Up")
      @account.create_activity :capture_charge, owner: @user, params: { card: @card.id, charge_id: charge[:charge_id] }
      @account.create_activity :add_funds_wallet, owner: @user, params: { amount: @amount, card: @card.id }
      create_payment_receipt(charge)
      create_sift_event(charge)
      @account.expire_wallet_balance
      return true
    rescue Stripe::CardError => e
      log_error(e)
    rescue Stripe::StripeError => e
      ErrorLogging.new.track_exception(e, extra: { current_user: @user, source: 'PaygTopupCard', amount: @amount })
      log_error(e)
    end
  end

  attr_reader :payment_receipt

  private
  
  def log_error(e)
    error = e.json_body[:error]
    @account.create_activity :auth_charge_failed, owner: @user, params: { card: @card.id, amount: @amount, reason: e.message }
    create_sift_event(nil, error)
    errors << "Card Failure: #{e.message}"
    return false
  end

  def create_payment_receipt(charge)
    value = @usd_amount * Invoice::MILLICENTS_IN_DOLLAR
    @payment_receipt = PaymentReceipt.create_receipt(@account, value, :billing_card)
    @payment_receipt.reference = charge[:charge_id]
    @payment_receipt.metadata = charge
    @payment_receipt.save
  end
  
  def create_sift_event(charge = nil, error = nil)
    payment_properties = @card.sift_billing_card_properties
    if charge
      success_properties = SiftProperties.stripe_success_properties(charge)
      payment_properties.merge! success_properties unless success_properties.nil?
      properties = payment_receipt.sift_payment_receipt_properties(payment_properties)
    else
      # If there is no charge, then transaction was failure
      cost = @usd_amount * Invoice::MILLICENTS_IN_DOLLAR
      payment_properties.merge!("$decline_reason_code" => error[:code])
      properties = SiftProperties.stripe_failure_properties(@account, cost, error, payment_properties)
    end
    CreateSiftEvent.perform_async("$transaction", properties)
  rescue StandardError => e
    ErrorLogging.new.track_exception(e, extra: { user: @user.id, source: 'PaygTopupCardTask#create_sift_event' })
  end
end
