require 'rails_helper'

RSpec.describe System, type: :model do

  it 'adds the system values if needed' do
    expect {System.set(:system_val, 8)}.to change {System.count}.by(1)
    expect {System.set(:system_val, 5)}.not_to change {System.count}
    record = System.find_by key: 'system_val'
    expect(record.value).to eq "5"
  end

  it 'gets the proper system value' do
    System.create(key: 'system_val', value: '5')
    expect(System.get(:system_val)).to eq '5'
  end

  it 'returns empty string if key is not valid' do
    expect(System.get(:system_val)).to eq ''
  end

  it 'returns default value  if key is not valid' do
    expect(System.get(:system_val, default: 'default')).to eq 'default'
  end

  it 'has unique keys' do
    System.create!(key: 'system_val', value: '5')
    expect {System.create!(key: 'system_val', value: '9')}.to raise_error ActiveRecord::RecordInvalid
  end
end
