require 'rails_helper'
include NegativeBalanceProtection
include NegativeBalanceProtection::Actions

describe ShutdownActionEmailToUser do
  let(:user) { FactoryGirl.create(:user) }
  let(:scope) {ShutdownActionEmailToUser.new(user)}
  
  it "should initialize properly" do
    expect(scope.instance_variable_get(:@user)).to be
  end
  
  it "should send shutdown action email to user" do
    mailer = double('Mailer')
    expect(NegativeBalanceMailer).to receive(:shutdown_action_email_to_user).
                                  with(user).and_return(mailer)
    expect(mailer).to receive(:deliver_now)
    scope.perform
  end
end