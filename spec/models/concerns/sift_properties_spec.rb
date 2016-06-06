require 'rails_helper'

describe SiftProperties do

  it 'should return valid user properties' do
    user = FactoryGirl.create(:user)
    @properties = user.sift_user_properties
  end
  
  it 'should return valid billing card properties' do
    card = FactoryGirl.create(:billing_card)
    @properties = card.sift_billing_card_properties
  end
  
  it 'should return valid billing address properties' do
    card = FactoryGirl.create(:billing_card)
    @properties = card.sift_billing_address_properties
  end
  
  it 'should return valid server properties' do
    server = FactoryGirl.create(:server)
    @properties = server.sift_server_properties
  end
  
  it 'should return valid invoice properties' do
    invoice = FactoryGirl.create(:invoice)
    @properties = invoice.sift_invoice_properties
  end
  
  it 'should return valid payment receipt properties' do
    payment_receipt = FactoryGirl.create(:payment_receipt)
    @properties = payment_receipt.sift_payment_receipt_properties
  end
  
  it 'should return valid charge properties' do
    charge = FactoryGirl.create(:charge)
    @properties = charge.sift_charge_properties
  end
  
  it 'should return valid credit note properties' do
    credit_note = FactoryGirl.create(:credit_note)
    @properties = credit_note.sift_credit_note_properties
  end
  
  it 'should return valid stripe success properties' do
    payment_receipt = FactoryGirl.create(:payment_receipt)
    payment_receipt.metadata = {"charge_id":"ch_abcd123","currency":"usd","amount":2500,"card":{"id":"card_abcd11112222","type":"Visa","last4":"4242","customer":"cus_123","country":"US","cvc_check":"pass","address_line1_check":nil,"address_zip_check":"pass","funding":"credit","brand":"Visa"},"captured":true}
    @properties = SiftProperties.stripe_success_properties(payment_receipt.metadata)
  end
  
  it 'should return valid stripe failure properties' do
    account = FactoryGirl.create(:account, :with_user)
    card = FactoryGirl.create(:billing_card)
    payment_properties = card.sift_billing_card_properties
    error = {charge: 'abcdef123456'}
    @properties = SiftProperties.stripe_failure_properties(account, 2500, error, payment_properties)
  end
  
  xit 'should return valid Paypal properties' do
    @properties = SiftProperties.paypal_properties(paypal_request)
  end
  
  xit 'should return valid Paypal success properties' do
    @properties = SiftProperties.paypal_success_properties(paypal_request, paypal_response)
  end
  
  xit 'should return valid Paypal failure properties' do
    @properties = SiftProperties.paypal_failure_properties(acount, paypal_response)
  end
  
  xit 'should return valid label properties' do
    @properties = SiftProperties.sift_label_properties(is_bad, reasons)
  end
  
  after :each do
    expect(@properties).not_to be_nil
    expect(@properties).to be_kind_of(Hash)
  end
  
end
