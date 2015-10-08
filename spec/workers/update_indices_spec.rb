require 'rails_helper'

describe UpdateIndices do
  context "enqueing jobs" do
    before(:each) do
      Sidekiq::Testing.fake!
    end
    it "should enque one job" do
      expect {
        UpdateIndices.perform_async
        UpdateIndices.perform_async
      }.to change(UpdateIndices.jobs, :size).by(1)
    end
  end
end