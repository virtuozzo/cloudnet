class PaygController < ApplicationController
  def add_funds
    render 'add_funds', layout: false
  end
  
  def show_add_funds
    render partial: 'show_add_funds', layout: false
  end

  def confirm_card_payment
    @amount = params[:amount]
    @account = current_user.account

    if !@account.primary_billing_card.present?
      @error = 'You do not have a billing card associated with your account.'
    else
      @last4 = @account.primary_billing_card.last4
    end

    render partial: 'card_confirm_content', layout: false
  end

  def card_payment
    @amount = params[:amount]
    @task = PaygTopupCardTask.new(current_user.account, @amount, ip)
    if @task.process
      unpaid_invoices = current_user.account.invoices.not_paid
      ChargeInvoicesTask.new(current_user, unpaid_invoices).process unless unpaid_invoices.empty?
    end
  rescue => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'Payg#CardPayment' })
  ensure
    render partial: 'card_payment_complete', layout: false
  end

  def paypal_request
    @amount = params[:amount]
    @task = PaygTopupPaypalRequestTask.new(current_user.account, @amount, request, ip)

    if @task.process
      redirect_to @task.popup_uri
    else
      render partial: 'paypal_request', layout: false
    end
  end

  def paypal_success
    token = params[:token]
    payer_id = params[:PayerID]

    @task = PaygTopupPaypalResponseTask.new(current_user.account, token, payer_id)
    if @task.process
      unpaid_invoices = current_user.account.invoices.not_paid
      ChargeInvoicesTask.new(current_user, unpaid_invoices).process unless unpaid_invoices.empty?
    end
  rescue => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'Payg#PaypalSuccess' })
  ensure
    render partial: 'paypal_success', layout: false
  end

  def paypal_failure
    render partial: 'paypal_failure', layout: false
  end
end
