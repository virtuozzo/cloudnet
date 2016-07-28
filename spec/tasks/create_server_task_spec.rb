require 'rails_helper'
require 'stripe'

describe CreateServerTask do
  before do
    @user     = FactoryGirl.create(:user_onapp)
    @account  = @user.account
    @wizard   = FactoryGirl.create(:server_wizard, :with_wallet, user: @user)
    @card     = @wizard.card
    @invoice  = Invoice.generate_prepaid_invoice([@wizard], @account)
    @initial_balance = @account.wallet_balance
    @payment_receipts = @account.payment_receipts.with_remaining_cost

    allow_any_instance_of(CreateServer).to receive_messages(process: { 'id' => '12345' })
    allow(MonitorServer).to receive(:perform_async).and_return(true)
    server_double = double('Server', id: 123, destroy: true, provisioner_role: 'ping', update_attribute: true, validation_reason: 0, sift_server_properties: {})
    allow(server_double).to receive(:monitor_and_provision).and_return(true)
    allow_any_instance_of(ServerWizard).to receive_messages(save_server_details: server_double)
  end
  
  describe 'Using Wallet funds' do
    it 'should debit funds from Wallet for the full amount' do
      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to eq(0)
      @account.reload
      expect(@initial_balance - @invoice.total_cost).to eq(@account.wallet_balance)
    end

    it 'should not build server if Wallet could not be charged' do
      expect_any_instance_of(SentryLogging).to receive(:raise).with(RuntimeError)
      expect(@wizard).to receive(:calculate_remaining_cost).and_raise "mock error"

      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to be > 0
    end
    
    it 'should refund Wallet funds if Server could not be created' do
      expect_any_instance_of(SentryLogging).to receive(:raise).with(Faraday::Error::ClientError)
      expect(PaymentReceipt).to receive(:refund_used_notes).exactly(1).times
      allow_any_instance_of(CreateServer).to receive(:process).and_raise Faraday::Error::ClientError.new('Help!')
      
      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to be > 0
    end

    it 'should debit Wallet for a partial amount if there are credit notes with remaining balances' do
      cn1 = FactoryGirl.create(:credit_note, account: @user.account, remaining_cost: 100_000)
      cn2 = FactoryGirl.create(:credit_note, account: @user.account, remaining_cost: 100_000)

      cost = @invoice.total_cost - 200_000
      expect(PaymentReceipt).to receive(:charge_account)
        .with(@payment_receipts, cost)
        .and_return(Hash[@payment_receipts.collect { |p| [p.id, p.remaining_cost] }])
      expect(CreditNote).to receive(:refund_used_notes).exactly(0).times

      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to eq(0)
    end

    it 'should debit Wallet for the full amount if there are credit notes with no remaining balances' do
      cn1 = FactoryGirl.create(:credit_note, account: @user.account, remaining_cost: 0)

      cost = @invoice.total_cost
      expect(PaymentReceipt).to receive(:charge_account)
        .with(@payment_receipts, cost)
        .and_return(Hash[@payment_receipts.collect { |p| [p.id, p.remaining_cost] }])

      expect(CreditNote).to receive(:refund_used_notes).exactly(0).times

      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to eq(0)
    end

    it 'should not debit from Wallet if there are credit notes with remaining balances larger than amount' do
      cn1 = FactoryGirl.create(:credit_note, account: @user.account, remaining_cost: @invoice.total_cost + 1000)
      expect(PaymentReceipt).to receive(:charge_account).exactly(0).times
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
      expect(PaymentReceipt).to receive(:refund_used_notes).exactly(1).times
      expect_any_instance_of(CreateServer).to receive(:process).exactly(1).times

      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to eq(1)
    end

    it 'should fail if the server comes back with no remote ID' do
      allow_any_instance_of(CreateServer).to receive_messages(process: { 'id' => nil })
      expect(PaymentReceipt).to receive(:refund_used_notes).exactly(1).times
      expect_any_instance_of(CreateServer).to receive(:process).exactly(1).times

      task = CreateServerTask.new(@wizard, @user)
      task.process
      expect(task.errors.length).to eq(1)
    end

    it 'should fail if the server throws a Faraday error' do
      expect_any_instance_of(SentryLogging).to receive(:raise).with(instance_of(Faraday::Error::ClientError))
      allow_any_instance_of(CreateServer).to receive(:process).and_raise Faraday::Error::ClientError.new('Help!')
      expect(PaymentReceipt).to receive(:refund_used_notes).exactly(1).times

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
    it "should generate a credit note for time remaining until the server's next invoice" do
      
      Timecop.freeze Time.utc(2015,2,16) do
        FactoryGirl.create :server
        invoice = FactoryGirl.create(:invoice)
        invoice.invoice_items << FactoryGirl.create(:invoice_item, invoice: invoice)
      end
      expect(Server.count).to eq 1
      
      Timecop.freeze Time.utc(2015,2,23) do
        server = Server.first
        server.create_credit_note_for_time_remaining
      end
      expect(CreditNote.count).to eq 1

      cn = CreditNote.first
      hours = cn.credit_note_items.first.metadata.first[:hours]
      
      expect(hours).to eq 504
    end
  end

  describe 'Charging Wallet' do
    it 'should not do any refunds if Wallet debit succeeds' do
      cost = @invoice.total_cost
      expect(PaymentReceipt).to receive(:charge_account)
        .with(@payment_receipts, cost)
        .and_return(Hash[@payment_receipts.collect { |p| [p.id, p.remaining_cost] }])

      expect(CreditNote).to receive(:refund_used_notes).exactly(0).times
      expect(PaymentReceipt).to receive(:refund_used_notes).exactly(0).times

      task = CreateServerTask.new(@wizard, @user)
      expect { task.process }.to change { Invoice.count }.by(1)
      expect(task.errors.length).to eq(0)
    end

    it 'should do a credit note refund if Wallet debit fails' do
      FactoryGirl.create(:credit_note, account: @user.account, remaining_cost: 100_000)
      
      expect_any_instance_of(SentryLogging).to receive(:raise).with(instance_of(RuntimeError))
      cost = @invoice.total_cost
      expect(PaymentReceipt).to receive(:charge_account)
        .with(@payment_receipts, cost - 100_000)
        .and_raise(RuntimeError)

      expect(CreditNote).to receive(:refund_used_notes).exactly(1).times

      task = CreateServerTask.new(@wizard, @user)
      expect { task.process }.to change { Invoice.count }.by(0)
      expect(task.errors.length).to eq(1)
    end
  end

  describe 'Creating Charges' do
    it 'should create one charge for Wallet if there are no credit notes used' do
      allow(Invoice).to receive_messages(generate_prepaid_invoice: @invoice)
      task = CreateServerTask.new(@wizard, @user)
      expect { task.process }.to change { Charge.count }.by(1)

      @invoice.reload
      charge = Charge.where(invoice: @invoice).first
      expect(charge).to be_valid

      @invoice.reload
      Charge.where(invoice: @invoice).each { |c| expect(c.source_type).to eq('PaymentReceipt') }
      expect(@invoice.state).to eq(:paid)
    end

    it 'should create no charges for billing card if there are Wallet used for entire payment' do
      cn1 = FactoryGirl.create(:credit_note, account: @user.account, remaining_cost: @invoice.total_cost - 1000)
      cn2 = FactoryGirl.create(:credit_note, account: @user.account, remaining_cost: @invoice.total_cost + 1000)

      allow(Invoice).to receive_messages(generate_prepaid_invoice: @invoice)
      task = CreateServerTask.new(@wizard, @user)
      expect { task.process }.to change { Charge.count }.by(2)

      @invoice.reload
      Charge.where(invoice: @invoice).each { |c| expect(c.source_type).to eq('CreditNote') }
      expect(@invoice.state).to eq(:paid)
    end

    it 'should create Wallet charges if there are credit notes used for partial payment' do
      cn1 = FactoryGirl.create(:credit_note, account: @user.account, remaining_cost: @invoice.total_cost - 100_000)

      allow(Invoice).to receive_messages(generate_prepaid_invoice: @invoice)

      task = CreateServerTask.new(@wizard, @user)
      expect { task.process }.to change { Charge.count }.by(2)

      @invoice.reload
      charges = Charge.where(invoice: @invoice)
      expect(charges.first.source_type).to eq('CreditNote')
      expect(charges.first.source_id).to eq(cn1.id)
      expect(charges.second.source_type).to eq('PaymentReceipt')
      expect(charges.second.source_id).to eq(@payment_receipts.first.id)

      expect(@invoice.state).to eq(:paid)
    end
    
    it 'should create events at Sift' do
      expect { CreateServerTask.new(@wizard, @user).process }.to change(CreateSiftEvent.jobs, :size).by(4)
    end
  end
end
