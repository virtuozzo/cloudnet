require 'rails_helper'

RSpec.describe UserServerCount, :type => :model do
  def create_existing_server(user, date)
    create_server(user, date)
  end
  
  def create_deleted_server(user, date, span = (UserServerCount::DO_NOT_COUNT_VM_LASTING_LESS_DAYS + 1).days)
    create_server(user, date, span, true)
  end
  
  def create_server(user, date, span = 1.day, deleted = false)
    Timecop.freeze(date)
    server=FactoryGirl.create(:server, user: user)
    if deleted
      Timecop.freeze(date + span)
      server.delete
    end
    Timecop.return
    server
  end
  
  let(:server_date) { Time.new(2016,06,14,14,55,43) }
  let(:user) { FactoryGirl.create(:user) }
  
  context 'server deleted lasting longer than threshold time' do
    let!(:server1_deleted) {create_deleted_server(user, server_date)}
    let!(:server2_deleted) do
      create_deleted_server(user, server_date, 
                           UserServerCount::DO_NOT_COUNT_VM_LASTING_LESS_DAYS.days)
    end
    let(:server3_deleted) do
      create_deleted_server(user, server_date, 
                           UserServerCount::DO_NOT_COUNT_VM_LASTING_LESS_DAYS.days + 1.second)
    end
    
    it 'counts a server lasting proper time created during a day' do
      day = server_date - 3.hours
      expect(UserServerCount.deleted_servers(user, day).count).to eq 1
      expect(UserServerCount.all_servers(user, day).count).to eq 1
    end
  
    it 'counts a server lasting proper time created before a day' do
      day = server_date + 1.day
      expect(UserServerCount.deleted_servers(user, day).count).to eq 1
      expect(UserServerCount.all_servers(user, day).count).to eq 1
    end
  
    it 'counts a server lasting proper time deleted at a day' do
      day = server1_deleted.deleted_at + 1.hour
      expect(UserServerCount.deleted_servers(user, day).count).to eq 1
      expect(UserServerCount.all_servers(user, day).count).to eq 1
    end
    
    it 'counts server lasting proper time' do
      day = server3_deleted.deleted_at + 1.hour
      expect(UserServerCount.deleted_servers(user, day).count).to eq 2
      expect(UserServerCount.all_servers(user, day).count).to eq 2
    end
  end
  
  context 'server deleted lasting less than threshold time' do
    let!(:server_deleted) {create_deleted_server(user, server_date, 2.hours)}
    
    it 'is not counted' do
      day = server_date - 3.hours
      expect(UserServerCount.deleted_servers(user, day).count).to eq 0
      expect(UserServerCount.all_servers(user, day).count).to eq 0
    end
  end
  
  context 'existing server' do
    let!(:server) {create_server(user, server_date)}
    
    after(:each) { Timecop.return }
    
    it 'counts when lasting longer than threshold' do
      Timecop.freeze(server_date + UserServerCount::DO_NOT_COUNT_VM_LASTING_LESS_DAYS.days + 1.second)
      expect(UserServerCount.existing_servers(user, Time.now).count).to eq 1
      expect(UserServerCount.existing_servers(user, Time.now - 1.day).count).to eq 1
      expect(UserServerCount.all_servers(user, Time.now).count).to eq 1
      expect(UserServerCount.all_servers(user, Time.now - 1.day).count).to eq 1
    end
    
    it 'doesnt count when lasting less than threshold' do
      Timecop.freeze(server_date + UserServerCount::DO_NOT_COUNT_VM_LASTING_LESS_DAYS.days)
      expect(UserServerCount.existing_servers(user, Time.now).count).to eq 0
      expect(UserServerCount.existing_servers(user, Time.now - 1.day).count).to eq 0
      expect(UserServerCount.all_servers(user, Time.now).count).to eq 0
      expect(UserServerCount.all_servers(user, Time.now - 1.day).count).to eq 0
    end
  end
  
  context 'instance methods listing servers' do
    let!(:server1) {create_server(user, server_date)}
    let!(:server2) {create_server(user, server_date + 1.second)}
    let!(:server1_deleted) {create_deleted_server(user, server_date - 1.day)}
    let!(:server2_deleted) {create_deleted_server(user, server_date, 1.hour)}
    
    before(:each) do
      day = server_date
      Timecop.freeze(server_date + UserServerCount::DO_NOT_COUNT_VM_LASTING_LESS_DAYS.days + 1.second)
      ds = UserServerCount.deleted_servers(user, day).count
      es = UserServerCount.existing_servers(user, Time.now).count
      @data = FactoryGirl.create(:user_server_count, date: day, user: user, servers_count: ds + es)
    end
    
    after(:each) { Timecop.return }
    
    it 'lists existing servers lasting proper time' do
      expect(@data.existing_servers).to eq [server1]
      expect(user.servers.count).to eq 2
    end
    
    it 'lists deleted servers lasting proper time' do
      expect(@data.deleted_servers).to eq [server1_deleted]
      expect(user.servers.only_deleted.count).to eq 2
    end
    
    it 'lists all servers lasting proper time' do
      expect(@data.all_servers).to include(server1_deleted)
      expect(@data.all_servers).to include(server1)
      expect(@data.all_servers).not_to include(server2_deleted)
      expect(@data.all_servers).not_to include(server2)
      expect(user.servers.with_deleted.count).to eq 4
    end
  end
end
