require 'rails_helper'

RSpec.describe ServerIpAddress, :type => :model do
  let (:server_ip_address) { FactoryGirl.create(:server_ip_address) }
  
  it 'should be valid' do
    expect(server_ip_address).to be_valid
  end

  it 'should not be valid without an address' do
    server_ip_address.address = nil
    expect(server_ip_address).not_to be_valid
  end

  it 'should not be valid without a server' do
    server_ip_address.server = nil
    expect(server_ip_address).not_to be_valid
  end
  
end
