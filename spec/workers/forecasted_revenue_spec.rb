require 'rails_helper'

describe ForecastedRevenue do
  
  
  context "enqueing jobs" do
    before(:each) do
      Sidekiq::Testing.fake!
    end
    it "should enque one job" do
      expect {
        ForecastedRevenue.perform_async
        ForecastedRevenue.perform_async
      }.to change(ForecastedRevenue.jobs, :size).by(1)
    end
  end
  
  context "performing taks" do
    
    let(:coupon) {FactoryGirl.create(:coupon)}
    let(:serv1) {FactoryGirl.create(:server, memory: 1024, cpus: 1, disk_size: 20)}
    it "should calculate forecasted revenue for server" do
      serv1.user.account.coupon = coupon
      expect(serv1.forecasted_rev).to eq 0.0
      ForecastedRevenue.new.perform
      serv1.reload
      expect(serv1.forecasted_rev).to eq 55722240.0
    end
  end
end