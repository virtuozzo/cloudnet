require 'rails_helper'

describe RemoveCouponCodes do
  context "enqueing jobs" do
    before(:each) do
      Sidekiq::Testing.fake!
      Sidekiq::Worker.clear_all
    end
    it "should enque job" do
      expect {
        RemoveCouponCodes.perform_async
      }.to change(RemoveCouponCodes.jobs, :size).by(1)
    end
  end

  context "performing task" do
    let(:user) {  FactoryGirl.build(:user) }

    before(:each) do
      Timecop.freeze(7.month.ago) do
        user.servers << FactoryGirl.build(:server, memory: 512)
        user.servers << FactoryGirl.build(:server, memory: 1024)
        user.account.coupon = FactoryGirl.create(:coupon)
      end
    end

    it "removes coupon" do
      expect(user.account.coupon).to be
      subject.perform
      user.reload
      expect(user.account.coupon).to be_nil
    end

    it 'recalculates forecasted_revenue' do
      expect(user.forecasted_revenue).to eq 83919360
      subject.perform
      user.reload
      expect(user.forecasted_revenue).to eq 104899200
    end
  end
end