class PaygController < ApplicationController
  def add_funds
    render 'add_funds', layout: false
  end

  def confirm_card_payment
    @amount = params[:amount].to_i
    @account = current_user.account

    if !Payg::VALID_TOP_UP_AMOUNTS.include?(@amount)
      @error = 'Amount submitted is invalid. Please try again'
    elsif !@account.primary_billing_card.present?
      @error = 'You do not have a billing card associated with your account.'
    else
      @last4 = @account.primary_billing_card.last4
    end

    render partial: 'card_confirm_content', layout: false
  end

  def card_payment
    @amount = params[:amount].to_i
    @task = PaygTopupCardTask.new(current_user.account, @amount)
    @task.process

    render partial: 'card_payment_complete', layout: false
  end

  def paypal_request
    @amount = params[:amount].to_i
    @task = PaygTopupPaypalRequestTask.new(current_user.account, @amount, request)

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
    @task.process

    render partial: 'paypal_success', layout: false
  end

  def paypal_failure
    render partial: 'paypal_failure', layout: false
  end
end
