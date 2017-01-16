require 'rails_helper'

describe ServerEdit do
  context "enqueing jobs" do
    before(:each) do
      Sidekiq::Testing.fake!
      Sidekiq::Worker.clear_all
    end
    it "should enque job" do
      expect {
        ServerEdit.perform_async
      }.to change(ServerEdit.jobs, :size).by(1)
    end
  end

  context "performing task" do
    before(:each) do
      @edit_server_task = double('EditServerTask')
      allow(EditServerTask).to receive_messages(new: @edit_server_task)
    end

    it "should call EditServerTask properly" do
      expect(@edit_server_task).to receive(:edit_server)
      ServerEdit.new.perform(1,1,1,1,1)
    end
  end
end