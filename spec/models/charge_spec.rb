require 'rails_helper'

describe Charge do
  let(:charge) { FactoryGirl.create(:charge) }

  it 'is a valid charge' do
    expect(charge).to be_valid
  end

  it 'is invalid without an amount' do
    charge.amount = nil
    expect(charge).not_to be_valid
  end

  it 'is invalid without an invoice' do
    charge.invoice = nil
    expect(charge).not_to be_valid
  end

  it 'is invalid without a source' do
    charge.source_id = nil
    expect(charge).not_to be_valid
  end

  it 'should attempt to find the source of an object' do
    invoice = FactoryGirl.create(:invoice)
    charge.source = invoice

    expect(charge.source_id).to eq(invoice.id)
    expect(charge.source_type).to eq(invoice.class.to_s)
    expect(charge.source).to eq(invoice)
  end

  it 'should set the source class to the class of the source object' do
    obj = double('TestClass', id: 10)
    charge.source = obj
    expect(charge.source_type).to eq(obj.class.to_s)
  end
end
