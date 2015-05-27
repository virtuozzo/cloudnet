require 'rails_helper'

describe ChargeUnpaidInvoices do
  after :each do
    SidekiqUniqueJobs.redis_mock.flushdb
  end

  describe 'unpaid Prepaid invoices' do
    it 'should charge invoices using credit notes' do
      invoice = FactoryGirl.create :invoice, invoice_type: :prepaid, state: :unpaid
      FactoryGirl.create :invoice_item, invoice: invoice, net_cost: 10_000

      credit_note = FactoryGirl.create :credit_note, account: invoice.account
      FactoryGirl.create :credit_note_item, credit_note: credit_note, net_cost: 15_000

      FactoryGirl.create :user, account: invoice.account

      ChargeUnpaidInvoices.perform_async
      ChargeUnpaidInvoices.drain
      invoice.reload
      expect(invoice.state).to eq :paid
    end

    it 'should charge invoices using payment receipts' do
      invoice = FactoryGirl.create :invoice, invoice_type: :prepaid, state: :unpaid
      FactoryGirl.create :invoice_item, invoice: invoice, net_cost: 10_000

      FactoryGirl.create :payment_receipt, account: invoice.account

      FactoryGirl.create :user, account: invoice.account

      payment = double Payments
      expect(Payments).to_not receive(:new)

      ChargeUnpaidInvoices.perform_async
      ChargeUnpaidInvoices.drain
      invoice.reload
      expect(invoice.state).to eq :paid
    end

    it 'should charge invoices using a credit card' do
      invoice = FactoryGirl.create :invoice, invoice_type: :prepaid, state: :unpaid
      FactoryGirl.create :invoice_item, invoice: invoice, net_cost: 1_000_000

      FactoryGirl.create :user, account: invoice.account
      FactoryGirl.create :billing_card, account: invoice.account, fraud_verified: true

      payment = double Payments
      expect(Payments).to receive(:new).twice.and_return(payment)
      expect(payment).to receive(:auth_charge).and_return({charge_id: 1})
      expect(payment).to receive(:capture_charge)

      ChargeUnpaidInvoices.perform_async
      ChargeUnpaidInvoices.drain

      invoice.reload
      expect(invoice.state).to eq :paid
    end
  end

  describe 'unpaid PAYG invoices' do
    it 'should charge unpaid invoices using payment receipts' do
      invoice = FactoryGirl.create :invoice, invoice_type: :payg, state: :unpaid
      FactoryGirl.create :invoice_item, invoice: invoice, net_cost: 10_000

      FactoryGirl.create :payment_receipt, account: invoice.account

      FactoryGirl.create :user, account: invoice.account

      ChargeUnpaidInvoices.perform_async
      ChargeUnpaidInvoices.drain
      invoice.reload
      expect(invoice.state).to eq :paid
    end

    it 'should charge unpaid invoices using credit notes' do
      invoice = FactoryGirl.create :invoice, invoice_type: :payg, state: :unpaid
      FactoryGirl.create :invoice_item, invoice: invoice, net_cost: 10_000

      credit_note = FactoryGirl.create :credit_note, account: invoice.account
      FactoryGirl.create :credit_note_item, credit_note: credit_note, net_cost: 15_000

      FactoryGirl.create :user, account: invoice.account

      ChargeUnpaidInvoices.perform_async
      ChargeUnpaidInvoices.drain
      invoice.reload
      expect(invoice.state).to eq :paid
    end
  end
end
