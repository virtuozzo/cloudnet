require 'rails_helper'

RSpec.describe RiskyIpAddress, :type => :model do
  
  let(:user) { FactoryGirl.create(:user) }
  
  it 'should be valid' do
    risky_ip = RiskyIpAddress.create(ip_address: '0.0.0.0', account: user.account)
    expect(risky_ip).to be_valid
  end
  
end
