require 'rails_helper'
include NegativeBalanceProtection
include NegativeBalanceProtection::Actions

describe ShutdownAllServers do
  let(:user) { FactoryGirl.create(:user) }
  let!(:server1) {FactoryGirl.create(:server, user: user)} 
  let!(:server2) {FactoryGirl.create(:server, user: user)} 
  let(:scope) {ShutdownAllServers.new(user)}
  
  it "should initialize properly" do
    expect(scope.instance_variable_get(:@user)).to be
  end
  
  it "should send shutdown requests for all servers" do
    expect(scope).to receive(:shut_down).twice
    scope.perform
  end
  
  it "should call server shutdown task" do
    task = instance_double('ServerTasks')
    expect(ServerTasks).to receive(:new).and_return(task)
    expect(task).to receive(:perform).with(:shutdown, user.id, server1.id)
    scope.shut_down(server1)
  end
  
  it "should handle errors" do
    task = instance_double('ServerTasks')
    expect(scope).to receive(:log_error)
    expect(ServerTasks).to receive(:new).and_return(task)
    expect(task).to receive(:perform).with(:shutdown, user.id, server1.id).
                    and_raise(Faraday::ClientError.new('Test'))
    expect {scope.shut_down(server1)}.not_to raise_error
  end
end