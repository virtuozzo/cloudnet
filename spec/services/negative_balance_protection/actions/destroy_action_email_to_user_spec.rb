require 'rails_helper'
include NegativeBalanceProtection
include NegativeBalanceProtection::Actions

describe DestroyActionEmailToUser do
  let(:user) { FactoryGirl.create(:user) }
  let(:scope) {DestroyActionEmailToUser.new(user)}
  
  it "should initialize properly" do
    expect(scope.instance_variable_get(:@user)).to be
  end
  
  it "should send shutdown action email to user" do
    mailer = double('Mailer')
    expect(NegativeBalanceMailer).to receive(:destroy_action_email_to_user).
                                  with(user).and_return(mailer)
    expect(mailer).to receive(:deliver_now)
    scope.perform
  end
end