require 'rails_helper'

describe UptimeAllUpdate, :vcr do
  include_context :pingdom_env

  context "enqueing jobs" do
    before(:each) do
      Sidekiq::Testing.fake!
      Sidekiq::Worker.clear_all
    end
    it "should enque job" do
      expect {
        UptimeAllUpdate.perform_async
      }.to change(UptimeAllUpdate.jobs, :size).by(1)

    end

    it "should enque jobs for all particular servers" do
      UptimeAllUpdate.perform_async
      expect {
        #Based on VCR
        UptimeAllUpdate.drain
      }.to change(UptimeUpdateServers.jobs, :size).by(34)
    end
  end
end