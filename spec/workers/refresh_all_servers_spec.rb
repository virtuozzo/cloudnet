require 'rails_helper'

describe RefreshAllServers do
  it "should attempt to refresh all servers and it's events" do
    server1 = FactoryGirl.create(:server)
    server2 = FactoryGirl.create(:server)
    server3 = FactoryGirl.create(:server)

    tasks = double('ServerTasks', perform: true)
    allow(ServerTasks).to receive(:new).and_return(tasks)

    RefreshAllServers.new.perform
    expect(tasks).to have_received(:perform).at_least(6).times
  end
end
