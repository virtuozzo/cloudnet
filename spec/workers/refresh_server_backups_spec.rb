require 'rails_helper'

describe RefreshServerBackups do
  it 'should attempt to refresh backups on server' do
    server = FactoryGirl.create(:server)
    tasks = double('DiskTasks', perform: true)
    allow(ServerTasks).to receive(:new).and_return(tasks)

    RefreshServerBackups.new.perform(server.user_id, server.id)
    expect(tasks).to have_received(:perform).with(:refresh_backups, server.user_id, server.id)
  end
end
