class PaygTopupCardTask < BaseTask
  def initialize(account, usd_amount)
    @usd_amount = usd_amount.to_f
    @amount     = (@usd_amount * Payg::CENTS_IN_DOLLAR).to_i

    @account = account
    @user    = account.user
  end

  def process
    card = @account.primary_billing_card
    
    unless @account.valid_top_up_amounts.include?(@usd_amount.to_i)
      errors << 'Invalid top up amount'
      return false
    end

    unless card.present?
      errors << 'You do not have a billing card associated with your account.'
      return false
    end

    begin
      charge = Payments.new.auth_charge(@account.gateway_id, card.processor_token, @amount)
      @account.create_activity :auth_charge, owner: @user, params: { card: card.id, amount: @amount, charge_id: charge[:charge_id] }
      Payments.new.capture_charge(charge[:charge_id], "#{ENV['BRAND_NAME']} Top Up")
      @account.create_activity :capture_charge, owner: @user, params: { card: card.id, charge_id: charge[:charge_id] }
      @account.create_activity :add_funds_wallet, owner: @user, params: { amount: @amount, card: card.id }
      create_payment_receipt(charge[:charge_id])
      return true
    rescue Stripe::StripeError => e
      ErrorLogging.new.track_exception(e, extra: { current_user: @user, source: 'PaygTopupCard', amount: @amount })
      @account.create_activity :auth_charge_failed, owner: @user, params: { card: card.id, amount: @amount, reason: e.message }
      errors << "Card Failure: #{e.message}"
      return false
    end
  end

  attr_reader :payment_receipt

  private

  def create_payment_receipt(charge_id)
    value = @usd_amount * Invoice::MILLICENTS_IN_DOLLAR
    @payment_receipt = PaymentReceipt.create_receipt(@account, value, :billing_card)
    @payment_receipt.reference = charge_id
    @payment_receipt.save
  end
end
