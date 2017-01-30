require 'rails_helper'

describe MonitorServer do
  it 'should attempt to run the refresh events task' do
    server = FactoryGirl.create(:server)
    tasks = double('ServerTasks', perform: server)
    allow(ServerTasks).to receive(:new).and_return(tasks)

    MonitorServer.new.perform(server.id, server.user.id)
    expect(tasks).to have_received(:perform).with(:refresh_server, server.user.id, server.id, false, :monitoring)
    expect(tasks).to have_received(:perform).with(:refresh_events, server.user.id, server.id)
  end

  it 'should attempt to schedule the task again if the server is not on or off state' do
    server = FactoryGirl.create(:server, state: :pending)
    tasks  = double('ServerTasks', perform: server)
    allow(ServerTasks).to receive(:new).and_return(tasks)
    expect { MonitorServer.new.perform(server.id, server.user.id) }.to change(MonitorServer.jobs, :size).by(1)
  end

  it 'should not schedule the task again if server is in off or on state' do
    server = FactoryGirl.create(:server, state: :on)
    tasks  = double('ServerTasks', perform: server)
    allow(ServerTasks).to receive(:new).and_return(tasks)
    expect { MonitorServer.new.perform(server.id, server.user.id) }.to change(MonitorServer.jobs, :size).by(0)

    server2 = FactoryGirl.create(:server, state: :off)
    tasks = double('ServerTasks', perform: server2)
    allow(ServerTasks).to receive(:new).and_return(tasks)
    expect { MonitorServer.new.perform(server2.id, server.user.id) }.to change(MonitorServer.jobs, :size).by(0)
  end
end
