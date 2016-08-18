require 'rails_helper'

describe Invoice do
  let (:invoice) { FactoryGirl.create(:invoice) }

  it 'should be valid' do
    expect(invoice).to be_valid
  end

  it 'should give a max hours till next invoice' do
    allow(invoice.account).to receive_messages(hours_till_next_invoice: Account::HOURS_MAX - 1)
    expect(invoice.hours_till_next_invoice).to eq(Account::HOURS_MAX - 1)
    allow(invoice.account).to receive_messages(hours_till_next_invoice: Account::HOURS_MAX + 1)
    expect(invoice.hours_till_next_invoice).to eq(Account::HOURS_MAX)
  end

  it 'should return if there are no items associated with this invoice' do
    expect(invoice.items?).to be false
    invoice.invoice_items << FactoryGirl.create(:invoice_item, invoice: invoice)
    expect(invoice.items?).to be true
  end

  it 'should have VAT exempt status determined from the account' do
    account = invoice.account
    allow(account).to receive_messages(vat_exempt?: false)

    invoice.account = account
    expect(invoice.vat_exempt?).to be false

    allow(account).to receive_messages(vat_exempt?: true)
    invoice.account = account
    expect(invoice.vat_exempt?).to be true
  end

  describe 'Derive costs' do
    before(:each) do
      @item1 = FactoryGirl.create(:invoice_item, invoice: invoice, net_cost: Random.rand(100_000))
      @item2 = FactoryGirl.create(:invoice_item, invoice: invoice, net_cost: Random.rand(100_000))
      invoice.invoice_items << [@item1, @item2]
    end

    it 'should have some invoice items associated with the invoice' do
      expect(invoice.items?).to be true
    end

    it 'should have a net cost derived from the items' do
      expect(invoice.net_cost).to eq(@item1.net_cost + @item2.net_cost)
    end

    it 'should have a tax cost derived from the items' do
      expect(invoice.tax_cost).to eq(@item1.tax_cost + @item2.tax_cost)
    end

    it 'should have a total cost derived from the items' do
      expect(invoice.total_cost).to eq(@item1.total_cost + @item2.total_cost)
    end

    it 'should return 0 on all fronts if there are no items' do
      invoice.invoice_items = []
      expect(invoice.net_cost).to eq(0)
      expect(invoice.tax_cost).to eq(0)
      expect(invoice.total_cost).to eq(0)
    end

    describe 'remaining cost' do
      it 'should have remaining cost as full cost if no charges' do
        expect(invoice.charges.count).to eq(0)
        expect(invoice.remaining_cost).to eq(invoice.total_cost)
      end

      it 'should deduct remaining cost as charges are added' do
        charge1 = FactoryGirl.create(:charge, invoice: invoice)
        expect(invoice.remaining_cost).to eq(invoice.total_cost - charge1.amount)

        charge2 = FactoryGirl.create(:charge, invoice: invoice)
        invoice.reload
        expect(invoice.remaining_cost).to eq(invoice.total_cost - charge1.amount - charge2.amount)
      end
    end
  end

  describe 'Generating Invoices from Servers' do
    it 'should have no invoice items if passed in no servers' do
      i = Invoice.generate_prepaid_invoice([], invoice.account)
      expect(i.invoice_items.length).to eq(0)
    end

    it 'should have invoice items if passed in some servers' do
      server1 = FactoryGirl.create(:server)
      server2 = FactoryGirl.create(:server)

      i = Invoice.generate_prepaid_invoice([server1, server2], invoice.account)
      expect(i.invoice_items.length).to eq(2)
    end
  end

  describe 'Full Scale Invoice Generation Tests' do
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

    it 'should generate an appropriate invoice' do
      invoice = Invoice.generate_prepaid_invoice([@server1, @server2], @account)
      expect(invoice).not_to be_nil
      expect(invoice.invoice_items.length).to eq(2)
    end

    it 'should have costs calculated appropriately' do
      invoice = Invoice.generate_prepaid_invoice([@server1, @server2], @account)

      net_cost_server_1 = @server1.generate_invoice_item(Account::HOURS_MAX)[:net_cost]
      net_cost_server_2 = @server2.generate_invoice_item(Account::HOURS_MAX)[:net_cost]

      expect(invoice.net_cost).to eq(net_cost_server_1.round(-3) + net_cost_server_2.round(-3))
      expect(invoice.tax_cost).to eq((net_cost_server_1 * Invoice::TAX_RATE).round(-3) + (net_cost_server_2 * Invoice::TAX_RATE).round(-3))
      expect(invoice.total_cost).to eq(invoice.net_cost + invoice.tax_cost)
    end

    it 'should have no tax associated if VAT exempt' do
      allow(@account).to receive_messages(vat_exempt?: true)
      invoice = Invoice.generate_prepaid_invoice([@server1, @server2], @account)

      expect(invoice.tax_cost).to eq(0.0)
      expect(invoice.total_cost).to eq(invoice.net_cost + invoice.tax_cost)
    end

    describe 'coupon codes' do
      it "should have the same net cost if there isn't a coupon" do
        @account.coupon = nil
        invoice = Invoice.generate_prepaid_invoice([@server1, @server2], @account)
        expect(invoice.pre_coupon_net_cost).to eq(invoice.net_cost)
      end

      it "should have the same tax cost if there isn't a coupon" do
        @account.coupon = nil
        invoice = Invoice.generate_prepaid_invoice([@server1, @server2], @account)
        expect(invoice.pre_coupon_tax_cost).to eq(invoice.tax_cost)
      end

      it "should have the same total cost if there isn't a coupon" do
        @account.coupon = nil
        invoice = Invoice.generate_prepaid_invoice([@server1, @server2], @account)
        expect(invoice.pre_coupon_total_cost).to eq(invoice.total_cost)
      end

      it 'should have a discounted net cost if there is a coupon' do
        coupon = FactoryGirl.create(:coupon)
        @account.coupon = coupon

        invoice = Invoice.generate_prepaid_invoice([@server1, @server2], @account)
        net_cost_server_1 = @server1.generate_invoice_item(Account::HOURS_MAX)[:net_cost]
        net_cost_server_2 = @server2.generate_invoice_item(Account::HOURS_MAX)[:net_cost]
        expect(invoice.pre_coupon_net_cost).to eq(net_cost_server_1.round(-3) + net_cost_server_2.round(-3))
        expect(invoice.net_cost).to eq(invoice.pre_coupon_net_cost * (1 - (coupon.percentage / 100.0)))
      end
    end

    describe 'cent costs' do
      it 'should have a cent cost for pre coupon total cost' do
        coupon = FactoryGirl.create(:coupon)
        @account.coupon = coupon

        invoice = Invoice.generate_prepaid_invoice([@server1, @server2], @account)
        expect(invoice.pre_coupon_total_cost_cents).to eq(Invoice.milli_to_cents(invoice.pre_coupon_total_cost))
      end

      it 'should have a cent cost for total cost' do
        invoice = Invoice.generate_prepaid_invoice([@server1, @server2], @account)
        expect(invoice.total_cost_cents).to eq(Invoice.milli_to_cents(invoice.total_cost))
      end
    end
  end

  describe 'billing address' do
    before(:each) do
      @account = FactoryGirl.create(:account, :with_user)
    end

    it 'should allow setting and retrieving of an address' do
      card1 = FactoryGirl.create(:billing_card, account: @account, primary: true, fraud_verified: true)
      invoice = Invoice.generate_prepaid_invoice([], @account)
      expect(invoice.billing_address).to be_present
      expect(invoice.billing_address[:address1]).to eq(card1.address1)
    end

    it "should have nil if there isn't any address" do
      invoice = Invoice.generate_prepaid_invoice([], @account)
      expect(invoice.billing_address).to be_nil
    end
  end

  it 'should have a GBP amount of the total' do
    expect(Invoice.in_gbp(1234)).to eq(1234 * Invoice::USD_GBP_RATE)
    expect(Invoice.in_gbp(0)).to eq(0 * Invoice::USD_GBP_RATE)
  end
  
  it 'should create events at Sift' do
    expect { FactoryGirl.create(:invoice) }.to change(CreateSiftEvent.jobs, :size).by(1)
  end
end
