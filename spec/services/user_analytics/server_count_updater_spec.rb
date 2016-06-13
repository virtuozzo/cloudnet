require 'rails_helper'

describe UserAnalytics::ServerCountUpdater do
  
  context 'user with VM data count' do
    before(:all) do
      @test_date = Time.now + 20.days
      @user = FactoryGirl.create(:user)
      @user2 = FactoryGirl.create(:user)
      8.times do |i|
        FactoryGirl.create(:user_server_count, 
                           date: (@test_date - i.days), 
                           user: @user, servers_count: rand(5))
      end
    
      3.times do |i|
        FactoryGirl.create(:user_server_count, 
                           date: (@test_date - i.days), 
                           user: @user2, servers_count: rand(5))
      end
    end
  
    subject{ UserAnalytics::ServerCountUpdater.new(@user) }
  
    after(:each) { Timecop.return }
    after(:all) { User.destroy_all }
  
    it 'calculates start update date' do
      offset = (UserServerCount::DO_NOT_COUNT_VM_LASTING_LESS_DAYS + 1).days
      expect(subject.start_update_date).to eq @test_date.to_date - offset
    end
  
    it 'creates proper range of update days' do
      now = @test_date + 6.days
      Timecop.freeze(now.midnight)
      offset = (UserServerCount::DO_NOT_COUNT_VM_LASTING_LESS_DAYS + 1).days
      start = @test_date.to_date - offset
      expect(subject.update_range).to eq start..now.to_date
    end
  
    it "counts user's records" do
      expect(subject.number_of_records).to eq 8
    end
  
    it 'updates user data up to current date' do
      Timecop.freeze(@test_date + 6.days)
      subject.update_user
      expect(@user.server_count_history.maximum(:date)).to eq Date.today
    end
  
    it 'keeps declared amount of data' do
      data_stored_count = 4
      stub_const("UserAnalytics::ServerCountUpdater::MAX_DATAPOINTS_STORED_PER_USER", data_stored_count)
      Timecop.freeze(@test_date + 6.days)
      subject.update_user
      expect(@user.server_count_history.count).to eq data_stored_count
    end
  end
  
  describe 'user with no VM data count' do
    context 'recent user' do
      let(:user) { FactoryGirl.create(:user, created_at: 1.day.ago) }
      subject{ UserAnalytics::ServerCountUpdater.new(user) }
    
      it 'initialize data properly' do
        expect {subject.update_user}.to change {user.server_count_history.count}.by(2)
        expect(user.server_count_history.sum(:servers_count)).to eq 0
      end
    
      it 'counts servers lasting proper time' do
        FactoryGirl.create(:server, user: user, created_at: user.created_at)
        FactoryGirl.create(:server, user: user, created_at: user.created_at + 1.day)
      
        Timecop.freeze(user.created_at + 1.day + 1.second)
        subject.update_user
        expect(user.server_count_history.sum(:servers_count)).to eq 0
        Timecop.freeze(user.created_at + 2.days + 1.second)
        subject.update_user
        expect(user.server_count_history.sum(:servers_count)).to eq 3
        Timecop.freeze(user.created_at + 3.days + 1.second)
        subject.update_user
        expect(user.server_count_history.sum(:servers_count)).to eq 7
        expect(user.server_count_history.count).to eq 4
        Timecop.return
      end
    end
    
    context 'long lasting user' do
      let(:user) { FactoryGirl.create(:user, created_at: 100.days.ago) }
      subject{ UserAnalytics::ServerCountUpdater.new(user) }
      
      before(:each) do
        @data_stored_count = 5
        stub_const("UserAnalytics::ServerCountUpdater::MAX_DATAPOINTS_FOR_EXISTING_USER", @data_stored_count)
      end
      
      it 'sets date range properly' do
        start = Date.today - (UserAnalytics::ServerCountUpdater::MAX_DATAPOINTS_FOR_EXISTING_USER - 1).days
        expect(subject.update_range).to eq start..Date.today
      end
      
      it 'initialize data properly' do
        expect {subject.update_user}.to change {user.server_count_history.count}.by(@data_stored_count)
        expect(user.server_count_history.sum(:servers_count)).to eq 0
      end
    end
  end
  
  describe 'bulk update' do
    subject{ UserAnalytics::ServerCountUpdater }
    
    it 'prepares array of values' do
      Timecop.freeze(Time.now)
      result = [1,2,3].map {|i| "(#{i}, '#{Date.today - 1.day}', 0, '#{Time.now}', '#{Time.now}')"}
      expect(subject.bulk_values([1, 2, 3], Date.today - 1.day)).to eq result
      Timecop.return
    end
    
    it 'prepares sql statement' do
      values = [1,2,3].map {|i| "(#{i}, '#{Date.today - 1.day}', 0, '#{Time.now}', '#{Time.now}')"}
      insert = "INSERT INTO user_server_counts (user_id, date, servers_count, created_at, updated_at)"
      result = subject.bulk_sql(values)
      expect(result).to include(values.join(', '))
      expect(result).to include(insert)
    end
    
    it 'saves data in one sql statement' do
      3.times { FactoryGirl.create(:user) }
      expect {subject.bulk_zero_insert(User.ids)}.to change {UserServerCount.count}.by(3)
    end
    
    it 'doesnt allow for same record inserted twice' do
      3.times { FactoryGirl.create(:user) }
      expect {subject.bulk_zero_insert(User.ids)}.not_to raise_error
      expect {subject.bulk_zero_insert(User.ids)}.to raise_error(ActiveRecord::RecordNotUnique)
    end
    
    context 'removal old data' do
      let(:user1) { FactoryGirl.create(:user) }
      let(:user2) { FactoryGirl.create(:user) }
      let(:user3) { FactoryGirl.create(:user) }
      
      def create_server_count_data(user, amount)
        today = Date.today
        amount.times do |i|
          FactoryGirl.create(:user_server_count, 
                             date: (today - i.days), 
                             user: user, servers_count: rand(5))
        end
      end
      
      def last_server_count_date(user)
        user.server_count_history.order(date: :desc).limit(1).take.date
      end
      
      before(:each) do
        @data_stored_count = 5
        stub_const("UserAnalytics::ServerCountUpdater::MAX_DATAPOINTS_STORED_PER_USER", @data_stored_count)
      
        create_server_count_data(user1, @data_stored_count + 5)
        create_server_count_data(user2, @data_stored_count + 10)
        create_server_count_data(user3, @data_stored_count + 3)
      end
      
      it 'removes old data in one statement' do
        ids = [user1.id, user2.id]
        expect {subject.bulk_old_data_remove(ids)}.to change {UserServerCount.count}.by(-15)
        expect(user3.server_count_history.count).to eq (@data_stored_count + 3)
      end
      
      it 'updates and removes data' do
        ids = [user1.id, user2.id]
        Timecop.freeze(Time.now.midnight + 1.day)
        expect {subject.bulk_zero_update(ids)}.to change {UserServerCount.count}.by(-15)
        expect(last_server_count_date(user1)).to eq Date.today
        expect(last_server_count_date(user2)).to eq Date.today
        expect(last_server_count_date(user3)).to eq Date.today - 1.day
        Timecop.return
      end
    end
  end
end