require 'rails_helper'
include NegativeBalanceProtection
include NegativeBalanceProtection::ActionStrategies

describe Protector do
  let(:user) { FactoryGirl.create(:user) }
  let(:strategy) {UserConstraintsAdminConfirm}
  let(:protector) {Protector.new(user, strategy)}
  
  let(:strategy_double) {double('Strategy', action_list: [:action1, :action2])}
  let(:strategy_double2) {double('Strategy2', action_list: [:action1, :undefined_action])}
  let(:strategy_double3) {double('Strategy3', action_list: [:action1, :increment_notifications_delivered])}
  let(:strategy_double4) {double('Strategy2', action_list: [:action1, :shutdown_all_servers ])}
  
  it "should initialize properly" do
    expect(strategy).to receive(:new).with(user).and_return(strategy_double)
    expect(protector.instance_variable_get(:@user)).to be
    expect(protector.instance_variable_get(:@strategy)).to be
  end

  context "#counter_actions" do
    let(:action) {double('Action1')}
    let(:action_class_double) {double('ActionClass')}
    
    before(:each) do
      stub_const("NegativeBalanceProtection::Actions::Action1", action_class_double)
      stub_const("NegativeBalanceProtection::Actions::Action2", action_class_double)
    end
    
    it "should perform actions" do
      expect(action_class_double).to receive(:new).with(user).twice.and_return(action)
      expect(action).to receive(:perform).twice
      expect(strategy).to receive(:new).and_return(strategy_double)
      expect(strategy_double).to receive(:action_list)
      expect(protector).not_to receive(:increment_notifications)
      expect(user).not_to receive(:refresh_my_servers)
      expect {protector.counter_actions}.not_to change {user.notif_delivered}
    end
  
    it "should not perform undefined actions" do
      expect(strategy).to receive(:new).and_return(strategy_double2)
      expect(strategy_double2).to receive(:action_list)
      expect(action_class_double).to receive(:new).with(user).and_return(action)
      expect(action).to receive(:perform)
      expect(protector).not_to receive(:increment_notifications)
      expect(user).not_to receive(:refresh_my_servers)
      expect {protector.counter_actions}.not_to change {user.notif_delivered}
    end
    
    it "should increment delivered notifications" do
      expect(strategy).to receive(:new).and_return(strategy_double3)
      expect(strategy_double3).to receive(:action_list)
      expect(action_class_double).to receive(:new).with(user).and_return(action)
      expect(action).to receive(:perform)
      expect(protector).to receive(:increment_notifications).and_call_original
      expect(user).not_to receive(:refresh_my_servers)
      expect {protector.counter_actions}.to change {user.notif_delivered}.by(1)
    end
    
    it "should refresh user's servers after shutdown" do
      expect(strategy).to receive(:new).and_return(strategy_double4)
      expect(strategy_double4).to receive(:action_list)
      expect(action_class_double).to receive(:new).with(user).and_return(action)
      expect(action).to receive(:perform)
      expect(protector).not_to receive(:increment_notifications)
      expect(user).to receive(:refresh_my_servers)
      expect {protector.counter_actions}.not_to change {user.notif_delivered}
    end
  end
end