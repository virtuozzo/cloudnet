require 'rails_helper'

describe UptimeAllUpdate, :vcr do

  context "enqueing jobs" do
    before(:each) do
      Sidekiq::Testing.fake!
    end
    it "should enque one job" do
      expect {
        UptimeAllUpdate.perform_async
        UptimeAllUpdate.perform_async
      }.to change(UptimeAllUpdate.jobs, :size).by(1)
      
    end

    it "should enque jobs for all particular servers" do
      UptimeAllUpdate.perform_async
      expect {
        #Based on VCR
        UptimeAllUpdate.drain
      }.to change(UptimeUpdateServers.jobs, :size).by(13)
    end
  end
end