class PaygTopupPaypalResponseTask < BaseTask
  def initialize(account, token, payer_id)
    Paypal.sandbox! unless Rails.env.production?

    @account  = account
    @user     = account.user
    @token    = token
    @payer_id = payer_id
  end

  def process
    request = Paypal::Express::Request.new(
      username: PAYMENTS[:paypal][:api_user],
      password: PAYMENTS[:paypal][:api_pass],
      signature: PAYMENTS[:paypal][:api_signature]
    )

    details = request.details(@token) # GetExpressCheckoutDetails
    payment = Paypal::Payment::Request.new(amount: details.amount, description: "#{ENV['BRAND_NAME']} Wallet")

    response = request.checkout!(@token, @payer_id, payment)  # DoExpressCheckoutPayment
    create_payment_receipt(details.amount, response.token, response_to_hash(response))
    create_sift_event(details, response)
    return true
  end

  attr_reader :payment_receipt

  private

  def response_to_hash(response)
    response.instance_variables.each_with_object({}) { |var, hash| hash[var.to_s.delete('@')] = response.instance_variable_get(var) }
  end

  def create_payment_receipt(amount, token_id, metadata)
    existing_receipt = PaymentReceipt.find_by(reference: token_id)

    if existing_receipt.present?
      @payment_receipt = existing_receipt
    else
      value = amount.total.to_f * Invoice::MILLICENTS_IN_DOLLAR
      @payment_receipt = PaymentReceipt.create_receipt(@account, value, :paypal)
      @payment_receipt.reference = token_id
      @payment_receipt.metadata = metadata
      @payment_receipt.save
    end
  end
  
  def create_sift_event(details, response)
    payment_properties = {
      "$payment_type": "$third_party_processor",
      "$payment_gateway": "$paypal",
      "$paypal_payer_id": @payer_id,
      "$paypal_payer_email": details.payer.email,
      "$paypal_payer_status": details.payer.status,
      "$paypal_address_status": details.address_status,
      "$paypal_protection_eligibility": response.payment_info.first.protection_eligibility,
      "$paypal_payment_status": response.payment_info.first.payment_status
    }
    properties = payment_receipt.sift_payment_receipt_properties(payment_properties)
    CreateSiftEvent.perform_async("$transaction", properties)
  end
end
