require 'rails_helper'

describe CreditNote do
  let(:credit_note) { FactoryGirl.create(:credit_note) }
  let(:user) { FactoryGirl.create(:user) }

  it 'should be valid' do
    expect(credit_note).to be_valid
  end

  it 'should have a credit note number' do
    expect(credit_note.credit_number).to be_present
    expect(credit_note.credit_number.length).to eq(9)
  end

  it 'should add a remaining cost from any deducted' do
    credit_note.remaining_cost = 20
    credit_note.add_remaining_cost(1000)
    credit_note.reload
    expect(credit_note.remaining_cost).to eq(1020)
  end

  describe 'using credit notes' do
    it 'should add a remaining cost from any deducted' do
      credit_note.remaining_cost = 20
      credit_note.add_remaining_cost(1000)
      credit_note.reload
      expect(credit_note.remaining_cost).to eq(1020)
    end

    it 'should not complain if I refund no used notes' do
      credit_note_1 = FactoryGirl.create(:credit_note, account: user.account, remaining_cost: 0)
      credit_note_2 = FactoryGirl.create(:credit_note, account: user.account, remaining_cost: 20)
      credit_note_3 = FactoryGirl.create(:credit_note, account: user.account, remaining_cost: 50)

      CreditNote.refund_used_notes({})
      [credit_note_1, credit_note_2, credit_note_3].each(&:reload)

      expect(credit_note_1.remaining_cost).to eq(0)
      expect(credit_note_2.remaining_cost).to eq(20)
      expect(credit_note_3.remaining_cost).to eq(50)
    end

    it 'should refund used notes' do
      credit_note_1 = FactoryGirl.create(:credit_note, account: user.account, remaining_cost: 0)
      credit_note_2 = FactoryGirl.create(:credit_note, account: user.account, remaining_cost: 20)
      credit_note_3 = FactoryGirl.create(:credit_note, account: user.account, remaining_cost: 50)

      CreditNote.refund_used_notes(credit_note_1.id => 100, credit_note_2.id => 200, credit_note_3.id => 300)
      [credit_note_1, credit_note_2, credit_note_3].each(&:reload)

      expect(credit_note_1.remaining_cost).to eq(0 + 100)
      expect(credit_note_2.remaining_cost).to eq(20 + 200)
      expect(credit_note_3.remaining_cost).to eq(50 + 300)
    end
  end

  it 'should give a max - 1 hours for credit note' do
    # TODO: Does not take into account when Time.now is in the last days of a month
    Timecop.freeze Time.zone.now.change(day: 15, month: 1) do
      allow(user.account).to receive_messages(hours_till_next_invoice: Account::HOURS_MAX)
      expect(credit_note.hours_till_next_invoice).to eq(Account::HOURS_MAX - 1)
      allow(user.account).to receive_messages(hours_till_next_invoice: Account::HOURS_MAX + 1)
      expect(credit_note.hours_till_next_invoice).to eq(Account::HOURS_MAX - 1)
    end
  end

  it 'should return if there are no items associated with this invoice' do
    expect(credit_note.items?).to be true
    expect(credit_note.credit_note_items.count).to be 2
    credit_note.credit_note_items << FactoryGirl.create(:credit_note_item, credit_note: credit_note)
    expect(credit_note.credit_note_items.count).to be 3
  end

  it 'should have VAT exempt status determined from the account' do
    allow(user.account).to receive(:vat_exempt?).and_return false
    credit_note.account = user.account
    expect(credit_note.vat_exempt?).to be false

    allow(user.account).to receive_messages(vat_exempt?: true)
    credit_note.account = user.account
    expect(credit_note.vat_exempt?).to be true
  end

  describe 'Derive costs' do
    before(:each) do
      @item1 = FactoryGirl.create(:credit_note_item, credit_note: credit_note, net_cost: Random.rand(100_000))
      @item2 = FactoryGirl.create(:credit_note_item, credit_note: credit_note, net_cost: Random.rand(100_000))
      credit_note.credit_note_items << [@item1, @item2]
    end

    it 'should have some invoice items associated with the credit note' do
      expect(credit_note.items?).to be true
    end

    it 'should have a net cost derived from the items' do
      expect(credit_note.net_cost).to eq(@item1.net_cost + @item2.net_cost)
    end

    it 'should have a tax cost derived from the items' do
      expect(credit_note.tax_cost).to eq(@item1.tax_cost + @item2.tax_cost)
    end

    it 'should have a total cost derived from the items' do
      expect(credit_note.total_cost).to eq(@item1.total_cost + @item2.total_cost)
    end

    it 'should return 0 on all fronts if there are no items' do
      credit_note.credit_note_items = []
      expect(credit_note.net_cost).to eq(0)
      expect(credit_note.tax_cost).to eq(0)
      expect(credit_note.total_cost).to eq(0)
    end
  end

  describe 'Generating Credit Notes from Servers' do
    it 'should have no credit note items if passed in no servers' do
      c = CreditNote.generate_credit_note([], user.account)
      expect(c.credit_note_items.length).to eq(0)
    end

    it 'should have credit note items if passed in some servers' do
      server1 = FactoryGirl.create(:server)
      server2 = FactoryGirl.create(:server)

      c = CreditNote.generate_credit_note([server1, server2], user.account)
      expect(c.credit_note_items.length).to eq(2)
    end
  end

  describe 'Full Scale Credit Note Generation Tests' do
    before(:each) do
      user = FactoryGirl.create(:user)
      @account = FactoryGirl.create(:account, user: user)
      allow(@account).to receive_messages(hours_till_next_invoice: Account::HOURS_MAX, vat_exempt?: false)

      @location1 = FactoryGirl.create(:location, price_memory: 5, price_disk: 6, price_cpu: 7, price_bw: 8)
      @location2 = FactoryGirl.create(:location, price_memory: 1, price_disk: 2, price_cpu: 3, price_bw: 4)
      template1 = FactoryGirl.create(:template, location: @location1)
      template2 = FactoryGirl.create(:template, location: @location2)

      @server1 = FactoryGirl.create(:server, user: user, location: @location1, template: template1, memory: 256, disk_size: 10, cpus: 4, bandwidth: 10)
      @server2 = FactoryGirl.create(:server, user: user, location: @location2, template: template2, memory: 2048, disk_size: 20, cpus: 8, bandwidth: 10)
    end

    it 'should generate an appropriate credit note' do
      credit_note = CreditNote.generate_credit_note([@server1, @server2], @account)
      expect(credit_note).not_to be_nil
      expect(credit_note.credit_note_items.length).to eq(2)
    end

    it 'should have costs calculated appropriately' do
      credit_note = CreditNote.generate_credit_note([@server1, @server2], @account)

      net_cost_server_1 = @server1.generate_invoice_item(Account::HOURS_MAX - 1)[:net_cost]
      net_cost_server_2 = @server2.generate_invoice_item(Account::HOURS_MAX - 1)[:net_cost]

      expect(credit_note.net_cost).to eq(net_cost_server_1.round(-3) + net_cost_server_2.round(-3))
      expect(credit_note.tax_cost).to eq((net_cost_server_1 * Invoice::TAX_RATE).round(-3) + (net_cost_server_2 * Invoice::TAX_RATE).round(-3))
      expect(credit_note.total_cost).to eq(credit_note.net_cost + credit_note.tax_cost)
    end

    it 'should have no tax associated if VAT exempt' do
      allow(@account).to receive_messages(vat_exempt?: true)
      credit_note = CreditNote.generate_credit_note([@server1, @server2], @account)

      expect(credit_note.tax_cost).to eq(0.0)
      expect(credit_note.total_cost).to eq(credit_note.net_cost + credit_note.tax_cost)
    end

    describe 'coupon codes' do
      it "should have the same net cost if there isn't a coupon" do
        @account.coupon = nil
        credit_note = CreditNote.generate_credit_note([@server1, @server2], @account)
        expect(credit_note.pre_coupon_net_cost).to eq(credit_note.net_cost)
      end

      it "should have the same tax cost if there isn't a coupon" do
        @account.coupon = nil
        credit_note = CreditNote.generate_credit_note([@server1, @server2], @account)
        expect(credit_note.pre_coupon_tax_cost).to eq(credit_note.tax_cost)
      end

      it "should have the same total cost if there isn't a coupon" do
        @account.coupon = nil
        credit_note = CreditNote.generate_credit_note([@server1, @server2], @account)
        expect(credit_note.pre_coupon_total_cost).to eq(credit_note.total_cost)
      end

      it 'should have a discounted net cost if there is a coupon' do
        coupon = FactoryGirl.create(:coupon)
        @account.coupon = coupon

        credit_note = CreditNote.generate_credit_note([@server1, @server2], @account)
        net_cost_server_1 = @server1.generate_invoice_item(Account::HOURS_MAX - 1)[:net_cost]
        net_cost_server_2 = @server2.generate_invoice_item(Account::HOURS_MAX - 1)[:net_cost]
        expect(credit_note.pre_coupon_net_cost).to eq(net_cost_server_1.round(-3) + net_cost_server_2.round(-3))
        expect(credit_note.net_cost).to eq(credit_note.pre_coupon_net_cost * (1 - (coupon.percentage / 100.0)))
      end
    end

    describe 'cent costs' do
      it 'should have a cent cost for pre coupon total cost' do
        coupon = FactoryGirl.create(:coupon)
        @account.coupon = coupon

        credit_note = CreditNote.generate_credit_note([@server1, @server2], @account)
        expect(credit_note.pre_coupon_total_cost_cents).to eq(Invoice.milli_to_cents(credit_note.pre_coupon_total_cost))
      end

      it 'should have a cent cost for total cost' do
        credit_note = CreditNote.generate_credit_note([@server1, @server2], @account)
        expect(credit_note.total_cost_cents).to eq(Invoice.milli_to_cents(credit_note.total_cost))
      end
    end
  end

  describe 'billing address' do
    before(:each) do
      @account = FactoryGirl.create(:account, :with_user)
    end

    it 'should allow setting and retrieving of an address' do
      card1 = FactoryGirl.create(:billing_card, account: @account, primary: true, fraud_verified: true)
      credit_note = CreditNote.generate_credit_note([], @account)
      expect(credit_note.billing_address).to be_present
      expect(credit_note.billing_address[:address1]).to eq(card1.address1)
    end

    it "should have nil if there isn't any address" do
      credit_note = CreditNote.generate_credit_note([], @account)
      expect(credit_note.billing_address).to be_nil
    end
  end

  describe 'Manually created credit notes' do
    before :each do
      recipient = FactoryGirl.create(:user)
      @issuer = FactoryGirl.create(:user, full_name: 'Credit note issuer')
      @account = FactoryGirl.create(:account, user: recipient)
      CreditNote.manually_issue(@account, '9.99', 'Testing credit notes', @issuer)
      @cn = CreditNote.first
    end

    it 'should create manually issued credit notes' do
      expect(@cn.account).to eq @account
      expect(@cn.remaining_cost).to eq 999_000
      items = @cn.credit_note_items
      expect(items.count).to eq 1
      only_item = items.first
      expect(only_item.description).to eq 'Testing credit notes'
      expect(only_item.source).to eq @issuer
    end

    it 'should not take into account any coupons for manually created credit notes' do
      coupon = FactoryGirl.create(:coupon)
      @account.coupon = coupon
      expect(@cn.coupon).to eq nil
    end
  end
  
  describe 'Trial issued credit notes' do
    before :each do
      @payments = double(Payments, auth_charge: { charge_id: 12_345 }, capture_charge: { charge_id: 12_345 })
      allow(Payments).to receive_messages(new: @payments)
      
      recipient = FactoryGirl.create(:user)
      @account = FactoryGirl.create(:account, user: recipient)
      card = FactoryGirl.create(:billing_card, account: @account, fraud_verified: true, processor_token: 'abcd1234')
      CreditNote.trial_issue(@account, card)
      @cn = CreditNote.first
    end

    it 'should create trial credit notes' do
      expect(@cn.account).to eq @account
      expect(@cn.remaining_cost).to eq CreditNote::TRIAL_CREDIT * Invoice::MILLICENTS_IN_DOLLAR
      items = @cn.credit_note_items
      expect(items.count).to eq 1
      only_item = items.first
      expect(only_item.description).to eq 'Trial Credit'
    end
  end
  
  it 'should create events at Sift' do
    expect { FactoryGirl.create(:credit_note) }.to change(CreateSiftEvent.jobs, :size).by(1)
  end
end
