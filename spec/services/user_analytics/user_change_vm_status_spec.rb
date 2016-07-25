require 'rails_helper'

describe UserAnalytics::UserChangeVmStatus do
  
  context 'shrinking' do
    before :each do
      @user = FactoryGirl.create(:user)
      date = Date.today
      35.times do |i|
        count = i < 15 ? 1 : 2
        FactoryGirl.create(:user_server_count, user: @user, date: date, servers_count: count)
        date -= 1.day
      end
    end
  
    subject{ UserAnalytics::UserChangeVmStatus.new(@user) }
  
    it 'marks as shrinking' do
      expect(subject.user_status).to eq :shrinking
    end
    
    it 'creates proper tag' do
      expect(Tag.count).to eq 0
      subject.tag_user_vm_trend
      expect(Tag.count).to eq 1
      expect(@user.tags.count).to eq 1
      expect(@user.tags.first.label).to eq 'shrinking'
    end
    
    it 'removes old tags' do
      @user.add_tags_by_label(UserAnalytics::UserChangeVmStatus::POSSIBLE_TAGS)
      expect(Tag.count).to eq 3
      subject.tag_user_vm_trend
      expect(Tag.count).to eq 3
      expect(@user.tags.count).to eq 1
      expect(@user.tags.first.label).to eq 'shrinking'
    end
  end
  
  context 'growing' do
    before :each do
      @user = FactoryGirl.create(:user)
      date = Date.today
      35.times do |i|
        count = i < 15 ? 2 : 1
        FactoryGirl.create(:user_server_count, user: @user, date: date, servers_count: count)
        date -= 1.day
      end
    end
  
    subject{ UserAnalytics::UserChangeVmStatus.new(@user) }
  
    it 'mark as growing' do
      expect(subject.user_status).to eq :growing
    end
  end
  
  context 'stable' do
    before :each do
      @user = FactoryGirl.create(:user)
      date = Date.today
      35.times do |i|
        count = i < 25 ? 1 : 2
        FactoryGirl.create(:user_server_count, user: @user, date: date, servers_count: count)
        date -= 1.day
      end
    end
  
    subject{ UserAnalytics::UserChangeVmStatus.new(@user) }
  
    it 'mark as stable' do
      expect(subject.user_status).to eq :stable
    end
  end
end