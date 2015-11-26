require 'rails_helper'
include NegativeBalanceProtection
include NegativeBalanceProtection::Actions

describe DestroyWarningEmailToUser do
  let(:user) { FactoryGirl.create(:user) }
  let(:scope) {DestroyWarningEmailToUser.new(user)}
  
  it "should initialize properly" do
    expect(scope.instance_variable_get(:@user)).to be
  end
  
  it "should send destroy warning email to user" do
    mailer = double('Mailer')
    expect(NegativeBalanceMailer).to receive(:destroy_warning_email_to_user).with(user).and_return(mailer)
    expect(mailer).to receive(:deliver_now)
    scope.perform
  end
end