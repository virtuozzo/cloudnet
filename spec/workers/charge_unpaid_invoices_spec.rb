require 'rails_helper'

describe ChargeUnpaidInvoices do
  it 'should charge unpaid prepaid invoices' do
    @invoice = FactoryGirl.create :invoice, invoice_type: :prepaid, state: :unpaid
    @user = FactoryGirl.create :user, account: @invoice.account
    ChargeUnpaidInvoices.perform_async
    ChargeUnpaidInvoices.drain
    @invoice.reload
    expect(@invoice.state).to eq :paid
  end

  it 'should charge unpaid payg invoices' do
    @invoice = FactoryGirl.create :invoice, invoice_type: :payg, state: :unpaid
    @user = FactoryGirl.create :user, account: @invoice.account
    ChargeUnpaidInvoices.perform_async
    ChargeUnpaidInvoices.drain
    @invoice.reload
    expect(@invoice.state).to eq :paid
  end
end
