require 'rails_helper'

describe CreateBackup do
 
  it 'should request a new backup at Onapp' do
    server = FactoryGirl.create(:server)
    tasks = double('DiskTasks', perform: server)
    allow(ServerTasks).to receive(:new).and_return(tasks)
    allow(RefreshServerBackups).to receive(:perform_in).and_return(true)

    CreateBackup.new.perform(server.user.id, server.id)
    expect(tasks).to have_received(:perform).with(:request_backup, server.user.id, server.id)
    expect(RefreshServerBackups).to have_received(:perform_in)
  end
 
end
