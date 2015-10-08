require 'rails_helper'

describe AssignIpAddress do
 
  it 'should assign new IP address at Onapp' do
    server = FactoryGirl.create(:server)
    tasks = double('IpAddressTasks', perform: true)
    allow(IpAddressTasks).to receive(:new).and_return(tasks)
    allow(MonitorServer).to receive(:perform_in).and_return(true)

    AssignIpAddress.new.perform(server.user.id, server.id)
    expect(tasks).to have_received(:perform).with(:assign_ip, server.user.id, server.id)
    expect(MonitorServer).to have_received(:perform_in)
  end
 
end