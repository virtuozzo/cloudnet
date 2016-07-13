require 'rails_helper'

RSpec.describe PaygController, :type => :controller do
  
  before(:each) { 
    sign_in_onapp_user 
    @billing_card = FactoryGirl.create(:billing_card, account: @current_user.account)
    @billing_card.update primary: true, fraud_verified: true
  }
  
  describe '#add_funds' do
    it 'should render add funds' do
      get :add_funds
      expect(response).to be_success
      expect(response).to render_template('payg/add_funds')
    end
  end
  
  describe '#confirm_card_payment' do
    it 'should render card confirm content' do
      get :confirm_card_payment, { amount: '5' }
      expect(response).to be_success
      expect(response).to render_template('payg/_card_confirm_content')
      expect(assigns(:last4)).to eq('1234')
    end
    
    it 'should not render card confirm content' do
      @billing_card.update_attribute :fraud_verified, false
      get :confirm_card_payment, { amount: '5' }
      expect(response).to be_success
      expect(response).to render_template('payg/_card_confirm_content')
      expect(assigns(:error)).to eq('You do not have a billing card associated with your account.')
    end
    
  end
  
  describe '#card_payment' do
    before(:each) do
      @payments = double(Payments, auth_charge: { charge_id: 12_345 }, capture_charge: { charge_id: 12_345 })
      allow(Payments).to receive_messages(new: @payments)
    end
    
    it 'should not process Wallet top-up because not fraud safe' do
      allow_any_instance_of(Account).to receive(:fraud_safe?).and_return(false)
      post :card_payment, { amount: '25' }
      expect(@current_user.account.wallet_balance).to eq(0)
    end
    
    it 'should process Wallet top-up using card payment' do
      allow_any_instance_of(Account).to receive(:fraud_safe?).and_return(true)
      post :card_payment, { amount: '25' }
      expect(@current_user.account.wallet_balance).to eq(2500000)
      expect(response).to be_success
      expect(response).to render_template('payg/_card_payment_complete')
    end
    
    it 'should not process if billing card not present' do
      @billing_card2 = FactoryGirl.create(:billing_card, account: @current_user.account)
      @billing_card.destroy
      post :card_payment, { amount: '10' }
      expect(@current_user.account.wallet_balance).to eq(0)
    end
    
    it 'should raise Stripe error' do
      allow_any_instance_of(SentryLogging).to receive(:raise).with(Stripe::StripeError)
      allow(@payments).to receive(:auth_charge).and_raise(Stripe::StripeError)
      post :card_payment, { amount: '10' }
      expect(@current_user.account.wallet_balance).to eq(0)
    end
    
    it 'should mark invoices as paid on top-up' do
      allow_any_instance_of(Account).to receive(:fraud_safe?).and_return(true)
      invoice = FactoryGirl.create(:invoice, account: @current_user.account)
      FactoryGirl.create_list(:invoice_item, 2, invoice: invoice, net_cost: 500000)
      post :card_payment, { amount: '25' }
      invoice.reload
      expect(invoice.state).to eq(:paid)
      expect(@current_user.account.reload.wallet_balance).to eq(1300000)
    end
    
    it 'should render on error' do
      allow_any_instance_of(SentryLogging).to receive(:raise).with(RuntimeError)
      allow(PaymentReceipt).to receive(:create_receipt).and_raise(RuntimeError)
      post :card_payment, { amount: '10' }
      expect(@current_user.account.wallet_balance).to eq(0)
      expect(response).to render_template('payg/_card_payment_complete')
    end
  end
  
  describe '#paypal_request' do    
    it 'should redirect to paypal' do      
      @payg_topup_paypal_request_task = double(PaygTopupPaypalRequestTask, process: true, popup_uri: 'https://www.sandbox.paypal.com/incontext?token=12345')
      allow(PaygTopupPaypalRequestTask).to receive_messages(new: @payg_topup_paypal_request_task)
      
      get :paypal_request, { amount: '5' }
      expect(@payg_topup_paypal_request_task).to have_received(:process)
      expect(@payg_topup_paypal_request_task).to have_received(:popup_uri)
      expect(response).to redirect_to('https://www.sandbox.paypal.com/incontext?token=12345')
    end
    
    it 'should render paypal request' do
      @paypal_express_request = double(Paypal::Express::Request)
      allow(Paypal::Express::Request).to receive_messages(new: @paypal_express_request)
      
      allow_any_instance_of(SentryLogging).to receive(:raise).with(Paypal::Exception::APIError)
      allow(@paypal_express_request).to receive(:setup).and_raise(Paypal::Exception::APIError)
      
      get :paypal_request, { amount: '5' }
      expect(response).to be_success
      expect(response).to render_template('payg/_paypal_request')
    end
  end
  
  describe '#paypal_success' do
    it 'should process PaygTopupPaypalResponseTask' do
      @payg_topup_paypal_response_task = double(PaygTopupPaypalResponseTask, process: true)
      allow(PaygTopupPaypalResponseTask).to receive(:new).and_return(@payg_topup_paypal_response_task)
      
      get :paypal_success, { PayerID: 'xxxx11111', token: 'qqqqwwww111122223333' }
      expect(response).to be_success
      expect(response).to render_template('payg/_paypal_success')
    end
  end
  
  describe '#paypal_failure' do
    it 'should render paypal failure' do      
      get :paypal_failure
      expect(response).to be_success
      expect(response).to render_template('payg/_paypal_failure')
    end
  end
  
end
