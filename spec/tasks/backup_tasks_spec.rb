require 'rails_helper'

xdescribe BackupTasks do
  
  before(:each) {
    @server = FactoryGirl.create(:server, user: @current_user)
    @server_backup = FactoryGirl.create(:server_backup, server: @server)
    @backup_task = BackupTasks.new
  }
  
  it 'should refresh backup of a server', :vcr do
    @backup_task.perform(:refresh_backup, @server.user_id, @server.id, @server_backup.id)
    expect(@server_backup.identifier).not_to be_empty
    expect(@server_backup.backup_created).not_to be_empty
  end
  
  it 'should restore backup on server' do
    @backup_task.perform(:restore_backup, @server.user_id, @server.id, @server_backup.id)
  end

  it 'should remove backup from server' do
    @backup_task.perform(:delete_backup, @server.user_id, @server.id, @server_backup.id)
  end
  
end