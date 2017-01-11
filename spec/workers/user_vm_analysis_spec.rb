require 'rails_helper'

describe UserVmAnalysis do

  context "enqueing jobs" do
    before(:each) do
      Sidekiq::Testing.fake!
      Sidekiq::Worker.clear_all
    end

    it "enques job" do
      expect {
        UserVmAnalysis.perform_async
      }.to change(UserVmAnalysis.jobs, :size).by(1)
    end
  end

  describe 'splitting users' do
    before(:each) do
      count_days = 2
      stub_const("UserServerCount::DO_NOT_COUNT_VM_LASTING_LESS_DAYS", count_days)

      FactoryGirl.create(:server)
      2.times { FactoryGirl.create(:user) }

      # counted as recent
      Timecop.freeze(Time.zone.now.midnight - 1.day) do
        @updated = FactoryGirl.create(:server)
        @updated.destroy
      end

      # not counted as recent
      Timecop.freeze(Time.zone.now.midnight - count_days.days - 1.second) do
        @not_updated = FactoryGirl.create(:server)
        @not_updated.destroy
      end
    end

    after(:all) do

    end

    it 'finds users with servers' do
      expect(subject.users_with_servers_recently.count).to eq 2
    end

    it 'finds users ids with no servers' do
      expect(subject.user_ids_with_no_servers_recently.count).to eq 3
    end

    it 'calls zero update in slices' do
      expect(UserAnalytics::ServerCountUpdater).to receive(:bulk_zero_update).exactly(3).times
      expect(subject).to receive(:user_ids_with_no_servers_recently).and_return (1..13).to_a
      subject.set_zero_vm_for_users_without_servers(5)
    end
  end
end