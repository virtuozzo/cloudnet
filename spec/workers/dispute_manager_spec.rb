require 'rails_helper'

describe DisputeManager, :vcr do
  
  let(:dispute_manager) { DisputeManager.new }

  context "enqueing jobs" do
    before(:each) do
      Sidekiq::Testing.fake!
    end
    it "should enqueue job for checking for disputes at Stripe" do
      expect {
        DisputeManager.perform_async(5)
      }.to change(DisputeManager.jobs, :size).by(1)
    end
  end
  
  context "perform jobs" do  
    
    let(:mailer_queue) { ActionMailer::Base.deliveries }
    
    before :each do
      agilecrm = double('UpdateAgilecrmContact', perform_async: true)
      allow(UpdateAgilecrmContact).to receive(:perform_async).and_return(agilecrm)
      allow(agilecrm).to receive(:perform_async).and_return(true)
      
      user_tasks = double('UserTasks', perform: true)
      allow(UserTasks).to receive(:new).and_return(user_tasks)
      allow(user_tasks).to receive(:perform).and_return(true)
      
      @server_tasks = double('ServerTasks', perform: true)
      allow(ServerTasks).to receive(:new).and_return(@server_tasks)
      allow(@server_tasks).to receive(:perform).and_return(true)
      
      @helpdesk = double('Helpdesk', new_ticket: true)
      allow(Helpdesk).to receive(:new).and_return(@helpdesk)
      allow(@helpdesk).to receive(:new_ticket).and_return(true)
      
      @user = FactoryGirl.create :user
      @server = FactoryGirl.create(:server, user: @user)
      FactoryGirl.create(:billing_card, account: @user.account)
      FactoryGirl.create(:payment_receipt, account: @user.account, pay_source: :billing_card, reference: 'ch_17xw1i4uZwGGrGulM87WR8DP')
      
      mailer_queue.clear
    end
   
    it 'should get list of disputes from Stripe and shutdown servers' do      
      VCR.use_cassette "DisputeManager/stripe_calls" do
        Timecop.freeze Time.now.change(day: 9, month: 4, hour: 10) do
          dispute_manager.perform
        end
        expect(@server_tasks).to have_received(:perform).with(:shutdown, @user.id, @server.id)
        @server.reload
        expect(@server.validation_reason).to eq(4)
        expect(mailer_queue.count).to eq 1
        expect(@helpdesk).to have_received(:new_ticket)
        expect(RiskyIpAddress.count).to eq 1
      end
    end
  end
end
