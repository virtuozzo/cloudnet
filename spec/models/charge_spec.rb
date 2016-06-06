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

  it 'should attempt to find the source of a charge' do
    credit_note = FactoryGirl.create(:credit_note)
    charge = FactoryGirl.create(:charge, source: credit_note)
    expect(charge.source_id).to eq(credit_note.id)
    expect(charge.source_type).to eq(credit_note.class.to_s)
    expect(charge.source).to eq(credit_note)
  end

  it 'should set the source class to the class of the source object' do
    obj = double('TestClass', id: 10)
    charge.source = obj
    expect(charge.source_type).to eq(obj.class.to_s)
  end
  
  it 'should create an event at Sift' do
    Sidekiq::Testing.inline! do
      charge = FactoryGirl.create(:charge)
      expect(@sift_client_double).to have_received(:perform).with(:create_event, "$transaction", charge.sift_charge_properties)
    end
  end
end
