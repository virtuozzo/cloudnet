require 'rails_helper'

describe DisputeHandler, :vcr do
  
  let(:dispute_handler) { DisputeHandler.new }

  context "enqueing jobs" do
    before(:each) do
      Sidekiq::Testing.fake!
    end
    it "should enqueue job for checking for disputes at Stripe" do
      expect {
        DisputeHandler.perform_async
      }.to change(DisputeHandler.jobs, :size).by(1)
    end
  end
  
  context "perform jobs" do  
    
    let(:mailer_queue) { ActionMailer::Base.deliveries }
    
    before :each do
      user_tasks = double('UserTasks', perform: true)
      allow(UserTasks).to receive(:new).and_return(user_tasks)
      allow(user_tasks).to receive(:perform).and_return(true)
      
      @server_tasks = double('ServerTasks', perform: true)
      allow(ServerTasks).to receive(:new).and_return(@server_tasks)
      allow(@server_tasks).to receive(:perform).and_return(true)
      
      @helpdesk = double('Helpdesk', new_ticket: true)
      allow(Helpdesk).to receive(:new).and_return(@helpdesk)
      allow(@helpdesk).to receive(:new_ticket).and_return(true)
      
      allow_any_instance_of(Account).to receive(:card_fingerprints).and_return(['abcd12345'])
      
      @user = FactoryGirl.create :user
      @server1 = FactoryGirl.create(:server, user: @user)
      @server2 = FactoryGirl.create(:server, user: @user)
      FactoryGirl.create(:billing_card, account: @user.account)
      FactoryGirl.create(:payment_receipt, account: @user.account, pay_source: :billing_card, reference: 'ch_17yRts4uZwGGrGulyMVldCQQ')
      FactoryGirl.create(:payment_receipt, account: @user.account, pay_source: :billing_card, reference: 'ch_17yRHr4uZwGGrGultW549N8F')
      
      mailer_queue.clear
    end
   
    it 'should get list of disputes from Stripe and shutdown servers' do      
      VCR.use_cassette "DisputeHandler/stripe_calls" do
        Timecop.freeze Time.zone.now.change(day: 10, month: 4, hour: 10, year: 2016) do
          dispute_handler.perform
        end
        expect(@server_tasks).to have_received(:perform).with(:shutdown, @user.id, @server1.id)
        expect(@server_tasks).to have_received(:perform).with(:shutdown, @user.id, @server2.id)
        @server1.reload
        @server2.reload
        expect(@server1.validation_reason).to eq(4)
        expect(@server2.validation_reason).to eq(4)
        expect(mailer_queue.count).to eq 2
        expect(@helpdesk).to have_received(:new_ticket).at_least(2).times
        expect(RiskyIpAddress.count).to eq 1
        expect(RiskyCard.count).to eq 1
        expect(@sift_client_double).to have_received(:perform).with(:create_event, "$chargeback", anything).twice
        label_properties = SiftProperties.sift_label_properties true, ["$chargeback"], "Received chargeback", "payment_gateway"
        expect(@sift_client_double).to have_received(:perform).with(:create_label, @user.id.to_s, label_properties).twice
        expect(@sift_device_double).to have_received(:perform).with(:get_devices, @user.id).twice
        # expect(@sift_device_double).to have_received(:perform).with(:label_device, anything, "bad")
      end
    end
  end
end
