require 'rails_helper'
include NegativeBalanceProtection
include NegativeBalanceProtection::Actions

describe DestroyActionEmailToAdmin do
  let(:user) { FactoryGirl.create(:user) }
  let(:scope) {DestroyActionEmailToAdmin.new(user)}
  
  it "should initialize properly" do
    expect(scope.instance_variable_get(:@user)).to be
  end
  
  it "should send shutdown action email to admin" do
    mailer = double('Mailer')
    expect(AdminMailer).to receive(:destroy_action).
                                  with(user).and_return(mailer)
    expect(mailer).to receive(:deliver_now)
    scope.perform
  end
end