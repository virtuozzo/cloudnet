require 'rails_helper'

xdescribe DiskTasks do
  
  before(:each) {
    @server = FactoryGirl.create(:server, user: @current_user)
    @disk_task = DiskTasks.new
  }
  
  it 'should refresh backups of a server', :vcr do
    @disk_task.perform(:refresh_backups, @server.user_id, @server.id)
    new_backup = @server.server_backups.last
    expect(new_backup.identifier).not_to be_empty
    expect(new_backup.backup_created).not_to be_empty
  end
  
  it 'should request new backup of server' do
    @disk_task.perform(:request_backup, @server.user_id, @server.id)
  end
  
end