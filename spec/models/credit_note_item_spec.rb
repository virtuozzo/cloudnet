require 'rails_helper'

describe CreditNoteItem do
  let (:credit_note_item) { FactoryGirl.create(:credit_note_item) }

  it 'should be valid' do
    expect(credit_note_item).to be_valid
  end

  it 'should not have any attributes related to cost assigned to it' do
    expect(credit_note_item.read_attribute(:net_cost)).to be_nil
    expect(credit_note_item.read_attribute(:tax_cost)).to be_nil
  end

  describe 'Costs' do
    it 'should calculate total cost dynamically' do
      credit_note_item.net_cost = Random.rand(1_000_000)
      credit_note_item.tax_cost = Random.rand(1_000_000)
      expect(credit_note_item.total_cost).to eq(credit_note_item.net_cost + credit_note_item.tax_cost)
    end

    it 'should allow the override of net cost' do
      expect(credit_note_item.net_cost).to eq(0)
      credit_note_item.net_cost = 3000
      expect(credit_note_item.net_cost).to eq(3000)
    end

    it 'should allow the override of tax cost' do
      expect(credit_note_item.tax_cost).to eq(0)
      credit_note_item.tax_cost = 3000
      expect(credit_note_item.tax_cost).to eq(3000)
    end
  end

  it 'should have a tax rate equivalent to that of the invoice if not VAT exempt' do
    credit_note = credit_note_item.credit_note
    allow(credit_note).to receive_messages(vat_exempt?: false)
    expect(credit_note_item.tax_rate).to eq(Invoice::TAX_RATE)
  end

  it 'should have a tax rate of zero if VAT Exempt in invoice' do
    credit_note = credit_note_item.credit_note
    allow(credit_note).to receive_messages(vat_exempt?: true)
    expect(credit_note_item.tax_rate).to eq(0.0)
  end

  it 'should determine tax code from invoice' do
    expect(credit_note_item.tax_code).to eq(credit_note_item.credit_note.tax_code)
    allow(credit_note_item.credit_note).to receive_messages(tax_code: 'abcd1234')
    expect(credit_note_item.tax_code).to eq('abcd1234')
  end

  describe 'metadata' do
    it 'should assign and parse metadata and return it in the format it went in' do
      credit_note_item.metadata = [{ abc: 123, de: 456 }]
      expect(credit_note_item.metadata).to eq([{ abc: 123, de: 456 }])
    end

    it 'should return an empty array for empty metadata' do
      credit_note_item.metadata = nil
      expect(credit_note_item.metadata).to eq([])
    end
  end

  it 'should attempt to find the source of an object' do
    credit_note = FactoryGirl.create(:credit_note)
    credit_note_item.source = credit_note

    expect(credit_note_item.source_id).to eq(credit_note.id)
    expect(credit_note_item.source_type).to eq(credit_note.class.to_s)
    expect(credit_note_item.source).to eq(credit_note)
  end

  it 'should set the source class to the class of the source object' do
    obj = double('TestClass', id: 10)
    credit_note_item.source = obj
    expect(credit_note_item.source_type).to eq(obj.class.to_s)
  end
end
