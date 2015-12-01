class PaygTopupPaypalRequestTask < BaseTask
  def initialize(account, usd_amount, request)
    Paypal.sandbox! unless Rails.env.production?

    @usd_amount = usd_amount
    @amount     = usd_amount * Payg::CENTS_IN_DOLLAR

    @account = account
    @user    = account.user
    @request = request
  end

  def process
    begin
      request = Paypal::Express::Request.new(
        username: PAYMENTS[:paypal][:api_user],
        password: PAYMENTS[:paypal][:api_pass],
        signature: PAYMENTS[:paypal][:api_signature]
      )

      pay_request = Paypal::Payment::Request.new(
        currency_code: :USD,
        amount: @usd_amount,
        items: [{
          name: 'Cloud.net Wallet',
          description: "Cloud Top Up for #{@user.full_name}",
          amount: @usd_amount,
          category: :Digital
        }]
      )

      helper = Rails.application.routes.url_helpers
      success_path = helper.payg_paypal_success_url(host: @request.host_with_port, protocol: 'https')
      failure_path = helper.payg_paypal_failure_url(host: @request.host_with_port, protocol: 'https')
      @response = request.setup(pay_request, success_path, failure_path, no_shipping: true)
    rescue Paypal::Exception::APIError => e
      ErrorLogging.new.track_exception(e, extra: { source: 'PaygTopupPaypalRequestTask', response: e.response })
      return false
    end
  end

  def popup_uri
    puts "Popup: #{@response.popup_uri}"
    @response.popup_uri
  end

  private

  def create_payment_receipt(charge_id)
    value = @usd_amount * Invoice::MILLICENTS_IN_DOLLAR
    @payment_receipt = PaymentReceipt.create_receipt(@account, value, :billing_card)
    @payment_receipt.reference = charge_id
    @payment_receipt.save
  end
end
