require 'rails_helper'
include NegativeBalanceProtection
include NegativeBalanceProtection::Actions

describe DestroyAllServersConfirmed do
  let(:user) { FactoryGirl.create(:user) }
  let!(:server1) {FactoryGirl.create(:server, user: user)} 
  let!(:server2) {FactoryGirl.create(:server, user: user)} 
  let(:scope) {DestroyAllServersConfirmed.new(user)}
  
  it "should initialize properly" do
    expect(scope.instance_variable_get(:@user)).to be
  end
  
  it "should send destroy requests for all servers" do
    expect(scope).to receive(:destroy).twice
    expect(scope).to receive(:destroy_confirmed_by_admin?).and_return(true)
    scope.perform
  end
  
  it "should call server shutdown task" do
    task = instance_double('ServerTasks')
    expect(ServerTasks).to receive(:new).and_return(task)
    expect(task).to receive(:perform).with(:destroy, user.id, server1.id)
    expect(server1).to receive(:destroy_with_ip)
    expect {scope.destroy(server1)}.to change {user.account.credit_notes.count}.by(1)
  end
  
  it "should handle errors" do
    task = instance_double('ServerTasks')
    expect(ServerTasks).to receive(:new).and_return(task)
    expect(scope).to receive(:log_error)
    expect(task).to receive(:perform).with(:destroy, user.id, server1.id).
                    and_raise(Faraday::ClientError.new('Test'))
    expect(server1).not_to receive(:destroy_with_ip)
    expect(server1).not_to receive(:create_credit_note_for_time_remaining)
    expect {scope.destroy(server1)}.not_to raise_error
  end
end