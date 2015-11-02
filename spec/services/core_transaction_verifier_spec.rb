require 'rails_helper'

describe CoreTransactionVerifier do
  
  before :each do
    allow_any_instance_of(UserTasks).to receive(:generate_user_credentials).and_return(
      login: 'auto_rspec_user',
      email: 'auto_rspec_user@onapp.com',
      password: 'Abcdef123456!'
    )
  end
  
  let(:user) {FactoryGirl.create(:user)}
  let(:server) {FactoryGirl.create(:server, disk_size: 20, memory: 512, cpus: 2, state: :on, user: user)}
  
  it "should return if no block passed" do
    verifier = CoreTransactionVerifier.new(user.id, server.id)
    expect(verifier.perform_transaction).to be_nil
  end
  
  xit "should wait untill transactions ended", :vcr do
    verifier = CoreTransactionVerifier.new(user.id, server.id)
    expect(verifier.perform_transaction {}).to be_nil
  end
end