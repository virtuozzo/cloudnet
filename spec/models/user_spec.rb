require 'rails_helper'
include NegativeBalanceProtection
include NegativeBalanceProtection::Actions

describe User do
  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }

  it 'has a valid factory' do
    expect(user).to be_valid
  end

  it 'is invalid without a full name' do
    user.full_name = ''
    expect(user).not_to be_valid
  end

  it 'contains a full name' do
    expect(user.full_name).not_to be_empty
  end

  it 'should not be an admin by default' do
    expect(user.admin).to be false
    expect(admin.admin).to be true
  end

  describe 'status' do
    it 'should have a pending status by default' do
      expect(user.status_pending?).to be true
    end

    it 'should push a job to the queue to create a user' do
      expect { user.save! }.to change(CreateOnappUser.jobs, :size).by(1)
    end
  end

  it 'should create an account when you create a user' do
    expect(user.account).not_to be_nil
  end
  
  it "should clear email notifications count" do 
    request = RequestForServerDestroyEmailToAdmin::REQUEST_SENT_NOT_CONFIRMED
    no_request = RequestForServerDestroyEmailToAdmin::REQUEST_NOT_SENT
    user.update(notif_delivered: 2, 
                last_notif_email_sent: Date.today,
                admin_destroy_request: request)

    expect(user.notif_delivered).to eq 2
    expect(user.last_notif_email_sent).to eq Date.today
    user.clear_unpaid_notifications
    expect(user.notif_delivered).to eq 0
    expect(user.last_notif_email_sent).to be_nil
    expect(user.admin_destroy_request).to eq no_request
  end
  
  it "should refresh user's servers" do
    FactoryGirl.create(:server, user: user)
    FactoryGirl.create(:server, user: user)
    server_task_double = double("ServerTask")
    expect(ServerTasks).to receive(:new).twice.and_return(server_task_double)
    expect(server_task_double).to receive(:perform).twice
    user.refresh_my_servers
  end
  
  xit "should use protection" do
    user.act_for_negative_balance
  end
  
  it 'should be eligible for trial credit' do
    expect(user.trial_credit_eligible?).to eq(true)
  end
  
  it 'should not be eligible for trial credit' do
    FactoryGirl.create(:billing_card, account: user.account)
    expect(user.trial_credit_eligible?).to eq(false)
  end
end
