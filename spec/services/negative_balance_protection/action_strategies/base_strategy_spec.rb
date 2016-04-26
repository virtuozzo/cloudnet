require 'rails_helper'
include NegativeBalanceProtection::ActionStrategies

describe BaseStrategy do
  let(:user) { FactoryGirl.create(:user) }
  let!(:server) {FactoryGirl.create(:server, user: user)}
  let(:strategy) {BaseStrategy}
  
  before(:each) do
    allow_any_instance_of(Account).
        to receive(:remaining_balance).and_return(200_000)
  end
  
  it "should initialize correctly" do
    expect(strategy.new(user)).to be
  end
  
  it "should set no actions array" do
    expect(strategy.new(user).no_actions).to eq []
    expect(strategy.new(user).action_list).to eq []
  end
  
  it "should check for no servers" do
    user1 = FactoryGirl.create(:user)
    expect(strategy.new(user1).no_servers_or_positive_balance?).to be_truthy
    FactoryGirl.create(:server, user: user1)
    expect(strategy.new(user1).no_servers_or_positive_balance?).to be_falsy
  end
  
  it "should check for positive balance" do
    expect(strategy.new(user).no_servers_or_positive_balance?).to be_falsy
    allow_any_instance_of(Account).to receive(:remaining_balance).and_return(20)
    expect(strategy.new(user).no_servers_or_positive_balance?).to be_truthy
  end
  
  it "should return actions for no servers" do
    user1 = FactoryGirl.create(:user)
    expect(strategy.new(user1).action_list).to eq [:clear_notifications_delivered]
  end
  
  context "#shutdown_less_emails_sent_than_defined_in_user_profile?" do
    it "should be true when delivered less notifications than in profile" do
      user1 = FactoryGirl.create(:user, notif_delivered: 2)
      user2 = FactoryGirl.create(:user, notif_before_shutdown: 6, notif_delivered: 5)
      expect(strategy.new(user).shutdown_less_emails_sent_than_defined_in_user_profile?).to be_truthy
      expect(strategy.new(user1).shutdown_less_emails_sent_than_defined_in_user_profile?).to be_truthy
      expect(strategy.new(user2).shutdown_less_emails_sent_than_defined_in_user_profile?).to be_truthy
    end
    
    it "should be false when delivered more notifications than in profile" do
      user1 = FactoryGirl.create(:user, notif_delivered: 3)
      user2 = FactoryGirl.create(:user, notif_delivered: 30)
      user3 = FactoryGirl.create(:user, notif_before_shutdown: 6, notif_delivered: 6)
      expect(strategy.new(user1).shutdown_less_emails_sent_than_defined_in_user_profile?).to be_falsy
      expect(strategy.new(user2).shutdown_less_emails_sent_than_defined_in_user_profile?).to be_falsy
      expect(strategy.new(user3).shutdown_less_emails_sent_than_defined_in_user_profile?).to be_falsy
    end
  end
  
  context "#minimum_time_passed_since_last_warning_email?" do
    it "should be true if no notification sent" do
      expect(strategy.new(user).minimum_time_passed_since_last_warning_email?).to be_truthy
    end
    
    it "should be false if last notification sent in less then specified hours" do
      user1 = FactoryGirl.create(:user, last_notif_email_sent: Time.now)
      user2 = FactoryGirl.create(:user, 
                last_notif_email_sent: Time.now - (BaseStrategy::MIN_HOURS_BETWEEN_EMAILS - 1).hours)
      expect(strategy.new(user1).minimum_time_passed_since_last_warning_email?).to be_falsy
      expect(strategy.new(user2).minimum_time_passed_since_last_warning_email?).to be_falsy
    end
    
    it "should be true if last notification sent in more then specified hours" do
      user1 = FactoryGirl.create(:user, 
                last_notif_email_sent: Time.now - (BaseStrategy::MIN_HOURS_BETWEEN_EMAILS).hours)
      expect(strategy.new(user1).minimum_time_passed_since_last_warning_email?).to be_truthy
    end
  end
  
  context "#emails_sent_as_in_profile_for_shutdown?" do
    it "it should be false when delivered less notifications than in profile" do
      user1 = FactoryGirl.create(:user, notif_delivered: 2)
      user2 = FactoryGirl.create(:user, notif_before_shutdown: 6, notif_delivered: 5)
      expect(strategy.new(user).emails_sent_as_in_profile_for_shutdown?).to be_falsy
      expect(strategy.new(user1).emails_sent_as_in_profile_for_shutdown?).to be_falsy
      expect(strategy.new(user2).emails_sent_as_in_profile_for_shutdown?).to be_falsy
    end
    
    it "it should be false when delivered more notifications than in profile" do
      user1 = FactoryGirl.create(:user, notif_delivered: 4)
      user2 = FactoryGirl.create(:user, notif_before_shutdown: 6, notif_delivered: 9)
      expect(strategy.new(user1).emails_sent_as_in_profile_for_shutdown?).to be_falsy
      expect(strategy.new(user2).emails_sent_as_in_profile_for_shutdown?).to be_falsy
    end
    
    it "it should be true when delivered notifications as in profile" do
      user1 = FactoryGirl.create(:user, notif_delivered: 3)
      user2 = FactoryGirl.create(:user, notif_before_shutdown: 6, notif_delivered: 6)
      expect(strategy.new(user1).emails_sent_as_in_profile_for_shutdown?).to be_truthy
      expect(strategy.new(user2).emails_sent_as_in_profile_for_shutdown?).to be_truthy
    end
  end
  
  context "#shutdown_more_emails_sent_than_defined_in_user_profile?" do
    it "it should be false when delivered less notifications than in profile" do
      user1 = FactoryGirl.create(:user, notif_delivered: 2)
      user2 = FactoryGirl.create(:user, notif_before_shutdown: 6, notif_delivered: 5)
      expect(strategy.new(user).shutdown_more_emails_sent_than_defined_in_user_profile?).to be_falsy
      expect(strategy.new(user1).shutdown_more_emails_sent_than_defined_in_user_profile?).to be_falsy
      expect(strategy.new(user2).shutdown_more_emails_sent_than_defined_in_user_profile?).to be_falsy
    end
    
    it "it should be false when delivered notifications as in profile" do
      user1 = FactoryGirl.create(:user, notif_delivered: 3)
      user2 = FactoryGirl.create(:user, notif_before_shutdown: 6, notif_delivered: 6)
      expect(strategy.new(user1).shutdown_more_emails_sent_than_defined_in_user_profile?).to be_falsy
      expect(strategy.new(user2).shutdown_more_emails_sent_than_defined_in_user_profile?).to be_falsy
    end
    
    it "it should be true when delivered more notifications than in profile" do
      user1 = FactoryGirl.create(:user, notif_delivered: 4)
      user2 = FactoryGirl.create(:user, notif_before_shutdown: 6, notif_delivered: 9)
      expect(strategy.new(user1).shutdown_more_emails_sent_than_defined_in_user_profile?).to be_truthy
      expect(strategy.new(user2).shutdown_more_emails_sent_than_defined_in_user_profile?).to be_truthy
    end
  end
  
  context "#destroy_less_emails_sent_than_defined_in_user_profile?" do
    it "should be true when delivered less notifications than in profile" do
      before_destroy = User::Limitable::NOTIF_BEFORE_DESTROY_DEFAULT
      user1 = FactoryGirl.create(:user, notif_delivered: before_destroy - 1)
      user2 = FactoryGirl.create(:user, notif_delivered: 50)
      user2.update_attribute(:notif_before_destroy, 66)
      expect(strategy.new(user).destroy_less_emails_sent_than_defined_in_user_profile?).to be_truthy
      expect(strategy.new(user1).destroy_less_emails_sent_than_defined_in_user_profile?).to be_truthy
      expect(strategy.new(user2).destroy_less_emails_sent_than_defined_in_user_profile?).to be_truthy
    end
    
    it "should be false when delivered more notifications than in profile" do
      user1 = FactoryGirl.create(:user, notif_delivered: user.notif_before_destroy)
      user2 = FactoryGirl.create(:user, notif_delivered: 30)
      user3 = FactoryGirl.create(:user, notif_delivered: 60)
      user3.update_attribute(:notif_before_destroy, 60)
      expect(strategy.new(user1).destroy_less_emails_sent_than_defined_in_user_profile?).to be_falsy
      expect(strategy.new(user2).destroy_less_emails_sent_than_defined_in_user_profile?).to be_falsy
      expect(strategy.new(user3).destroy_less_emails_sent_than_defined_in_user_profile?).to be_falsy
    end
  end
  
  context "#emails_sent_as_in_profile_for_destroy_or_more?" do
    it "it should be false when delivered less notifications than in profile" do
      before_destroy = User::Limitable::NOTIF_BEFORE_DESTROY_DEFAULT
      user1 = FactoryGirl.create(:user, notif_delivered: before_destroy - 1)
      user2 = FactoryGirl.create(:user, notif_delivered: 50)
      user2.update_attribute(:notif_before_destroy, 66)
      expect(strategy.new(user).emails_sent_as_in_profile_for_destroy_or_more?).to be_falsy
      expect(strategy.new(user1).emails_sent_as_in_profile_for_destroy_or_more?).to be_falsy
      expect(strategy.new(user2).emails_sent_as_in_profile_for_destroy_or_more?).to be_falsy
    end
    
    it "it should be true when delivered more notifications than in profile" do
      user1 = FactoryGirl.create(:user, notif_delivered: user.notif_before_destroy + 1)
      user2 = FactoryGirl.create(:user, notif_delivered: 65)
      user2.update_attribute(:notif_before_destroy, 60)
      expect(strategy.new(user1).emails_sent_as_in_profile_for_destroy_or_more?).to be_truthy
      expect(strategy.new(user2).emails_sent_as_in_profile_for_destroy_or_more?).to be_truthy
    end
    
    it "it should be true when delivered notifications as in profile" do
      user1 = FactoryGirl.create(:user, notif_delivered: user.notif_before_destroy)
      user2 = FactoryGirl.create(:user, notif_delivered: 60)
      user2.update_attribute(:notif_before_destroy, 60)
      expect(strategy.new(user1).emails_sent_as_in_profile_for_destroy_or_more?).to be_truthy
      expect(strategy.new(user2).emails_sent_as_in_profile_for_destroy_or_more?).to be_truthy
    end
  end
end