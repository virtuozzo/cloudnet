require 'rails_helper'
require 'stripe'

describe CreateServerTask do
  before do
    @user     = FactoryGirl.create(:user_onapp)
    @account  = @user.account
    @wizard   = FactoryGirl.create(:server_wizard_with_billing_card, user: @user)
    @card     = @wizard.card
    @invoice  = Invoice.generate_prepaid_invoice([@wizard], @account)

    @payments = double('Payments', auth_charge: { charge_id: 12_345 }, capture_charge: { charge_id: 12_345 })

    allow(Payments).to receive_messages(new: @payments)
    allow_any_instance_of(CreateServer).to receive_messages(process: { 'id' => '12345' })
    allow(MonitorServer).to receive(:perform_async).and_return(true)
    allow_any_instance_of(ServerWizard).to receive_messages(save_server_details: double(id: 123, destroy: true))
  end

  describe 'Authorizing Card Charge' do
    it 'should authorize a charge for the full amount if no credit notes' do
      cost = Invoice.milli_to_cents(@invoice.total_cost)

      expect(@payments).to receive(:auth_charge)
        .with(@account.gateway_id, @card.processor_token, cost)
        .and_return(charge_id: 12_345)

      expect(CreditNote).to receive(:refund_used_notes).exactly(0).times

      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to eq(0)
    end

    it 'should refund any credit notes if authorization fails' do
      expect_any_instance_of(SentryLogging).to receive(:raise).with(instance_of(Stripe::StripeError))
      cost = Invoice.milli_to_cents(@invoice.total_cost)
      expect(@payments).to receive(:auth_charge)
        .with(@account.gateway_id, @card.processor_token, cost)
        .and_raise Stripe::StripeError

      expect(CreditNote).to receive(:refund_used_notes).exactly(1).times

      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to be > 0
    end

    it 'should authorize a charge for a partial amount if there are credit notes with remaining balances' do
      cn1 = FactoryGirl.create(:credit_note, account: @user.account, remaining_cost: 100_000)
      cn2 = FactoryGirl.create(:credit_note, account: @user.account, remaining_cost: 100_000)

      cost = Invoice.milli_to_cents(@invoice.total_cost - 200_000)
      expect(@payments).to receive(:auth_charge)
        .with(@account.gateway_id, @card.processor_token, cost)
        .and_return(charge_id: 12_345)

      expect(CreditNote).to receive(:refund_used_notes).exactly(0).times

      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to eq(0)
    end

    it 'should authorize a charge for the full amount if there are credit notes with no remaining balances' do
      cn1 = FactoryGirl.create(:credit_note, account: @user.account, remaining_cost: 0)

      cost = Invoice.milli_to_cents(@invoice.total_cost)
      expect(@payments).to receive(:auth_charge)
        .with(@account.gateway_id, @card.processor_token, cost)
        .and_return(charge_id: 12_345)

      expect(CreditNote).to receive(:refund_used_notes).exactly(0).times

      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to eq(0)
    end

    it 'should not authorize a charge if there are credit notes with remaining balances larger than amount' do
      cn1 = FactoryGirl.create(:credit_note, account: @user.account, remaining_cost: @invoice.total_cost + 1000)
      expect(@payments).to receive(:auth_charge).exactly(0).times

      expect(CreditNote).to receive(:refund_used_notes).exactly(0).times

      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to eq(0)
    end
  end

  describe 'Creating Server' do
    it 'should not have any errors and not do any credit note refunds if server succeeds' do
      expect(CreditNote).to receive(:refund_used_notes).exactly(0).times
      expect_any_instance_of(CreateServer).to receive(:process).exactly(1).times

      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to eq(0)
    end

    it 'should fail if the server comes back with nil' do
      allow_any_instance_of(CreateServer).to receive_messages(process: nil)
      expect(CreditNote).to receive(:refund_used_notes).exactly(1).times
      expect_any_instance_of(CreateServer).to receive(:process).exactly(1).times

      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to eq(1)
    end

    it 'should fail if the server comes back with no remote ID' do
      allow_any_instance_of(CreateServer).to receive_messages(process: { 'id' => nil })
      expect(CreditNote).to receive(:refund_used_notes).exactly(1).times
      expect_any_instance_of(CreateServer).to receive(:process).exactly(1).times

      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to eq(1)
    end

    it 'should fail if the server throws a Faraday error' do
      expect_any_instance_of(SentryLogging).to receive(:raise).with(instance_of(Faraday::Error::ClientError))
      allow_any_instance_of(CreateServer).to receive(:process).and_raise Faraday::Error::ClientError.new('Help!')
      expect(CreditNote).to receive(:refund_used_notes).exactly(1).times

      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to eq(1)
    end

    it 'should succeed if nothing fails' do
      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to eq(0)
      expect(task.server).to be_present
    end
  end

  describe 'Destroying Server' do
    before do
      task = CreateServerTask.new(@wizard, @user)
      task.process
    end
    it 'should create a credit note and correct card charge amount' do
      # p Invoice.count
    end
  end

  describe 'Charging Card' do
    it 'should not do any credit note refunds if charge succeeds' do
      expect(@payments).to receive(:capture_charge)
        .with(12_345, kind_of(String)).and_return(charge_id: 12_345)

      expect(CreditNote).to receive(:refund_used_notes).exactly(0).times

      task = CreateServerTask.new(@wizard, @user)
      expect { task.process }.to change { Invoice.count }.by(1)
      expect(task.errors.length).to eq(0)
    end

    it 'should do a credit note refund if charge fails' do
      expect_any_instance_of(SentryLogging).to receive(:raise).with(instance_of(Stripe::StripeError))
      expect(@payments).to receive(:capture_charge)
        .with(12_345, kind_of(String)).and_raise Stripe::StripeError

      expect(CreditNote).to receive(:refund_used_notes).exactly(1).times

      task = CreateServerTask.new(@wizard, @user)
      expect { task.process }.to change { Invoice.count }.by(0)
      expect(task.errors.length).to eq(1)
    end
  end

  describe 'Creating Charges' do
    it 'should create one charge for the billing card if there are no credit notes used' do
      allow(Invoice).to receive_messages(generate_prepaid_invoice: @invoice)
      task = CreateServerTask.new(@wizard, @user)
      expect { task.process }.to change { Charge.count }.by(1)

      @invoice.reload
      charge = Charge.where(invoice: @invoice).first
      expect(charge).to be_valid

      @invoice.reload
      expect(@invoice.state).to eq(:paid)
    end

    it 'should create no charges for billing card if there are credit notes used for entire payment' do
      cn1 = FactoryGirl.create(:credit_note, account: @user.account, remaining_cost: @invoice.total_cost - 1000)
      cn2 = FactoryGirl.create(:credit_note, account: @user.account, remaining_cost: @invoice.total_cost + 1000)

      allow(Invoice).to receive_messages(generate_prepaid_invoice: @invoice)
      task = CreateServerTask.new(@wizard, @user)
      expect { task.process }.to change { Charge.count }.by(2)

      @invoice.reload
      Charge.where(invoice: @invoice).each { |c| expect(c.source_type).to eq('CreditNote') }
      expect(@invoice.state).to eq(:paid)
    end

    it 'should create charges for billing card if there are credit notes used for partial payment' do
      cn1 = FactoryGirl.create(:credit_note, account: @user.account, remaining_cost: @invoice.total_cost - 100_000)

      allow(Invoice).to receive_messages(generate_prepaid_invoice: @invoice)
      allow_any_instance_of(ServerWizard).to receive_messages(card: @card)

      task = CreateServerTask.new(@wizard, @user)
      expect { task.process }.to change { Charge.count }.by(2)

      @invoice.reload
      charges = Charge.where(invoice: @invoice)
      expect(charges.first.source_type).to eq('CreditNote')
      expect(charges.first.source_id).to eq(cn1.id)
      expect(charges.second.source_type).to eq('BillingCard')
      expect(charges.second.source_id).to eq(@card.id)

      expect(@invoice.state).to eq(:paid)
    end

    it "should not create a card charge if it's not more than the minimum amount" do
      cn1 = FactoryGirl.create(:credit_note, account: @user.account, remaining_cost: @invoice.total_cost - 10_000)

      allow(Invoice).to receive_messages(generate_prepaid_invoice: @invoice)
      allow_any_instance_of(ServerWizard).to receive_messages(card: @card)

      task = CreateServerTask.new(@wizard, @user)
      expect { task.process }.to change { Charge.count }.by(1)

      @invoice.reload
      charges = Charge.where(invoice: @invoice)
      expect(charges.first.source_type).to eq('CreditNote')
      expect(charges.first.source_id).to eq(cn1.id)

      expect(@invoice.state).to eq(:partially_paid)
      expect(Invoice.milli_to_cents(@invoice.remaining_cost)).to be > 0
      expect(Invoice.milli_to_cents(@invoice.remaining_cost)).to be < Invoice::MIN_CHARGE_AMOUNT
    end
  end
end
