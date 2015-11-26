require 'rails_helper'
include NegativeBalanceProtection
include NegativeBalanceProtection::Actions

describe DestroyWarning2daysEmailToAdmin do
  let(:user) { FactoryGirl.create(:user) }
  let(:scope) {DestroyWarning2daysEmailToAdmin.new(user)}
  
  it "should initialize properly" do
    expect(scope.instance_variable_get(:@user)).to be
  end
  
  it "should not send email if more than 2 days for destroy" do
    mailer = double('Mailer')
    expect(AdminMailer).not_to receive(:destroy_warning_email_to_admin)
    scope.perform
  end
  
  it "should send destroy warning email to user" do
    user1 = FactoryGirl.create(:user, notif_delivered: user.notif_before_destroy - 2)
    mailer = double('Mailer')
    expect(AdminMailer).to receive(:destroy_warning).with(user1).and_return(mailer)
    expect(mailer).to receive(:deliver_now)
    DestroyWarning2daysEmailToAdmin.new(user1).perform
  end
end