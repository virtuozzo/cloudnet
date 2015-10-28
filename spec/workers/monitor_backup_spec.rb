require 'rails_helper'

describe MonitorBackup do
  
  it 'should attempt to run the refresh backup task' do
    server = FactoryGirl.create(:server)
    server_backup = FactoryGirl.create(:server_backup, server: server)
    tasks = double('BackupTasks', perform: server)
    allow(BackupTasks).to receive(:new).and_return(tasks)

    MonitorBackup.new.perform(server.id, server_backup.id, server.user.id)
    expect(tasks).to have_received(:perform).with(:refresh_backup, server.user.id, server.id, server_backup.id)
  end
  
  it 'should attempt to schedule the task again if the backup is not built' do
    server = FactoryGirl.create(:server)
    server_backup = FactoryGirl.create(:server_backup, server: server, built: false)
    tasks  = double('BackupTasks', perform: server)
    allow(BackupTasks).to receive(:new).and_return(tasks)
    
    expect { MonitorBackup.new.perform(server.id, server_backup.id, server.user.id) }.to change(MonitorBackup.jobs, :size).by(1)
  end

end
