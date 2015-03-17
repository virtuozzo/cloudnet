require 'rails_helper'

describe InvoiceItem do
  let (:invoice_item) { FactoryGirl.create(:invoice_item) }

  it 'should be valid' do
    expect(invoice_item).to be_valid
  end

  it 'should not have any attributes related to cost assigned to it' do
    expect(invoice_item.read_attribute(:net_cost)).to be_nil
    expect(invoice_item.read_attribute(:tax_cost)).to be_nil
  end

  describe 'Costs' do
    it 'should calculate net cost dynamically' do
      # invoice_item.net_cost.should == 5 * 10 * 20
    end

    it 'should calculate tax cost dynamically' do
      # invoice_item.tax_cost.should == 5 * 10 * 20 * invoice_item.tax_rate
    end

    it 'should calculate total cost dynamically' do
      invoice_item.net_cost = Random.rand(1_000_000)
      invoice_item.tax_cost = Random.rand(1_000_000)
      expect(invoice_item.total_cost).to eq(invoice_item.net_cost + invoice_item.tax_cost)
    end

    it 'should allow the override of net cost' do
      expect(invoice_item.net_cost).to eq(0)
      invoice_item.net_cost = 3000
      expect(invoice_item.net_cost).to eq(3000)
    end

    it 'should allow the override of tax cost' do
      expect(invoice_item.tax_cost).to eq(0)
      invoice_item.tax_cost = 3000
      expect(invoice_item.tax_cost).to eq(3000)
    end
  end

  it 'should have a tax rate equivalent to that of the invoice if not VAT exempt' do
    invoice = invoice_item.invoice
    allow(invoice).to receive_messages(vat_exempt?: false)
    expect(invoice_item.tax_rate).to eq(Invoice::TAX_RATE)
  end

  it 'should have a tax rate of zero if VAT Exempt in invoice' do
    invoice = invoice_item.invoice
    allow(invoice).to receive_messages(vat_exempt?: true)
    expect(invoice_item.tax_rate).to eq(0.0)
  end

  it 'should determine tax code from invoice' do
    expect(invoice_item.tax_code).to eq(invoice_item.invoice.tax_code)
    allow(invoice_item.invoice).to receive_messages(tax_code: 'abcd1234')
    expect(invoice_item.tax_code).to eq('abcd1234')
  end

  describe 'metadata' do
    it 'should assign and parse metadata and return it in the format it went in' do
      invoice_item.metadata = [{ abc: 123, de: 456 }]
      expect(invoice_item.metadata).to eq([{ abc: 123, de: 456 }])
    end

    it 'should return an empty array for empty metadata' do
      invoice_item.metadata = nil
      expect(invoice_item.metadata).to eq([])
    end
  end

  it 'should attempt to find the source of an object' do
    invoice = FactoryGirl.create(:invoice)
    invoice_item.source = invoice

    expect(invoice_item.source_id).to eq(invoice.id)
    expect(invoice_item.source_type).to eq(invoice.class.to_s)
    expect(invoice_item.source).to eq(invoice)
  end

  it 'should set the source class to the class of the source object' do
    obj = double('TestClass', id: 10)
    invoice_item.source = obj
    expect(invoice_item.source_type).to eq(obj.class.to_s)
  end

end
