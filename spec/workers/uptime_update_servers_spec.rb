require 'rails_helper'


describe UptimeUpdateServers do
  
  context "enqueing jobs" do
    before(:each) do
      Sidekiq::Testing.fake!
    end
    it "enque job for update one server" do
      expect {
        UptimeUpdateServers.perform_async(5)
      }.to change(UptimeUpdateServers.jobs, :size).by(1)
    end
  end
end