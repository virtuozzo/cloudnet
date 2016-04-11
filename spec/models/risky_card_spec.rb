require 'rails_helper'

RSpec.describe RiskyCard, :type => :model do
  
  let(:user) { FactoryGirl.create(:user) }
  
  it 'should be valid' do
    risky_card = RiskyCard.create(fingerprint: 'abcd12345', account: user.account)
    expect(risky_card).to be_valid
  end
  
end
