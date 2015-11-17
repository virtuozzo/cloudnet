require 'rails_helper'
include NegativeBalanceProtection
include NegativeBalanceProtection::Actions

describe RequestForServerDestroyEmailToAdmin do
  let(:user) { FactoryGirl.create(:user) }
  let(:scope) {RequestForServerDestroyEmailToAdmin.new(user)}
  
  it "should initialize properly" do
    expect(scope.instance_variable_get(:@user)).to be
  end
  
  it "should have constants defined" do
    klass = scope.class
    expect(klass::REQUEST_NOT_SENT).to be
    expect(klass::REQUEST_SENT_NOT_CONFIRMED).to be
    expect(klass::REQUEST_SENT_CONFIRMED).to be
  end
  
  it "should send request for destroy email to admin" do
    mailer = double('Mailer')
    expect(AdminMailer).to receive(:request_for_server_destroy).
                        with(user).and_return(mailer)
    expect(mailer).to receive(:deliver_now)
    scope.perform
  end
end