require 'rails_helper'

describe BandwidthChecker do
  let(:server) { FactoryGirl.create(:server) }
  subject { BandwidthChecker.new(server) }

  context 'bandwidth not exceeded' do
    before :each do
      allow(subject).to receive(:paid_bandwidth).and_return 0
      allow(subject).to receive(:reported_bandwidth).and_return 0
    end

    it 'user bandwidth threshold equals 5GB' do
      expect(subject.user_notification_threshold).to eq 5 * 1024
    end

    it 'admin bandwidth threshold equals as declared' do
      bw_admin = BandwidthChecker::NOTIFICATION_ADMIN_AFTER_EXCEEDED_GB * 1024
      expect(subject.admin_notification_threshold).to eq bw_admin
    end

    it 'has no bandwidth exceeded' do
      expect(subject.bandwidth_threshold_exceeded?(subject.user_notification_threshold)).to eq false
    end
  end

  context 'bandwidth exceeded' do
    before :each do
      allow(subject).to receive(:paid_bandwidth).and_return(6 * 1024)
      allow(subject).to receive(:reported_bandwidth).and_return 0
    end

    it 'has user bandwidth exceeded' do
      expect(subject.bandwidth_threshold_exceeded?(subject.user_notification_threshold)).to eq true
    end

    it 'has no admin bandwidth exceeded' do
      expect(subject.bandwidth_threshold_exceeded?(subject.admin_notification_threshold)).to eq false
    end

    it 'has admin bandwidth exceeded' do
      bw_admin = BandwidthChecker::NOTIFICATION_ADMIN_AFTER_EXCEEDED_GB * 1024
      allow(subject).to receive(:paid_bandwidth).and_return(bw_admin + 1)
      expect(subject.bandwidth_threshold_exceeded?(subject.admin_notification_threshold)).to eq true
    end
  end

  context 'informing emails' do
    def initial_conditions
      allow(subject).to receive(:paid_bandwidth).and_return(100)
      @sent_user_double = double('sent_user_double')
      expect(@sent_user_double).to receive(:notify_bandwidth_exceeded)
      expect(server.exceed_bw_value).to eq 0
      expect(server.exceed_bw_user_notif).to eq 0
      expect(server.exceed_bw_user_last_sent).to be_nil
      expect(server.exceed_bw_admin_notif).to eq 0
    end

    it 'informs user and updates fields' do
      initial_conditions
      expect(NotifyUsersMailer).to receive(:delay).and_return(@sent_user_double)
      Timecop.freeze Time.utc(2015,2,16)
      subject.inform_user
      expect(server.exceed_bw_value).to eq 100
      expect(server.exceed_bw_user_notif).to eq 1
      expect(server.exceed_bw_user_last_sent).to eq Time.utc(2015,2,16)
      Timecop.return
    end

    it 'informs admin and updates fields' do
      initial_conditions
      expect(AdminMailer).to receive(:delay).and_return(@sent_user_double)
      Timecop.freeze Time.utc(2015,2,16)
      subject.inform_admin
      expect(server.exceed_bw_admin_notif).to eq 1
      Timecop.return
    end
  end
end