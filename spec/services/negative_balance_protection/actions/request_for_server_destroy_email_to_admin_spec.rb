require 'rails_helper'
include NegativeBalanceProtection
include NegativeBalanceProtection::Actions

describe RequestForServerDestroyEmailToAdmin do
  let(:user) { FactoryGirl.create(:user) }
  let(:scope) {RequestForServerDestroyEmailToAdmin.new(user)}
  let(:r_not_sent) {RequestForServerDestroyEmailToAdmin::REQUEST_NOT_SENT}
  let(:r_sent) {RequestForServerDestroyEmailToAdmin::REQUEST_SENT_NOT_CONFIRMED}
  
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
    expect(scope).to receive(:set_email_sent_status)
    scope.perform
  end
  
  it "should set sent_email attribute in user" do
    expect(scope).to receive(:send_email_to_admin)
    expect(user.admin_destroy_request).to eq r_not_sent
    scope.perform
    expect(user.admin_destroy_request).to eq r_sent
  end
end