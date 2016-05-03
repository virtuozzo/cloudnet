RSpec.shared_examples "negative balance integration" do
  let(:r_not_sent) {RequestForServerDestroyEmailToAdmin::REQUEST_NOT_SENT}
  let(:r_sent) {RequestForServerDestroyEmailToAdmin::REQUEST_SENT_NOT_CONFIRMED}
  let(:r_sent_conf) {RequestForServerDestroyEmailToAdmin::REQUEST_SENT_CONFIRMED}
  
  def action_double(klass)
    action = instance_double(klass)
    allow(klass).to receive(:new).and_return(action)
    expect(action).to receive(:perform)
  end
  
  it "should perform before shutdown" do
    expect {scope.check_user(user)}.to change {user.notif_delivered}.by(1)
    expect(mailer_q.count).to eq 1
    mail = mailer_q.first
    expect(mail.subject).to match "shutdown warning"
    expect(mail.to).to eq [user.email]
  end
  
  it "should perform shutdown" do
    action_double(ShutdownAllServers)
    user.update_attribute(:notif_delivered, user.notif_before_shutdown)
    
    expect {scope.check_user(user)}.to change {user.notif_delivered}.by(1)
    expect(mailer_q.count).to eq 2
    mail_user = mailer_q.first
    mail_admin = mailer_q.second
    expect(mail_user.subject).to match "all your servers shut down"
    expect(mail_user.to).to eq [user.email]
    expect(mail_admin.subject).to match "Automatic shutdown - #{user.full_name}"
    expect(mail_admin.to).to eq(ENV['MAILER_ADMIN_RECIPIENTS'].delete(' ').split(","))
  end
  
  it "should perform before destroy - more than 2 days to destroy" do
    action_double(ShutdownAllServers)
    user.update_attribute(:notif_delivered, user.notif_before_shutdown + 1)
    
    expect {scope.check_user(user)}.to change {user.notif_delivered}.by(1)
    expect(mailer_q.count).to eq 1
    mail_user = mailer_q.first
    expect(mail_user.subject).to match "DESTROY warning"
    expect(mail_user.to).to eq [user.email]
  end
  
  it "should perform before destroy - 2 days to destroy" do
    action_double(ShutdownAllServers)
    user.update_attribute(:notif_delivered, user.notif_before_destroy - 1)
    
    expect {scope.check_user(user)}.to change {user.notif_delivered}.by(1)
    expect(mailer_q.count).to eq 2
    mail_user = mailer_q.first
    mail_admin = mailer_q.second
    expect(mail_user.subject).to match "DESTROY warning"
    expect(mail_user.to).to eq [user.email]
    expect(mail_admin.subject).to match "DESTROY warning! - #{user.full_name}"
    expect(mail_admin.to).to eq(ENV['MAILER_ADMIN_RECIPIENTS'].delete(' ').split(","))
  end
  
  it "should perform admin_acknowledge" do
    user.update_attribute(:notif_delivered, user.notif_before_destroy)
    
    expect(user.admin_destroy_request).to eq r_not_sent
    expect {scope.check_user(user)}.not_to change {user.notif_delivered}
    expect(user.admin_destroy_request).to eq r_sent
    expect(mailer_q.count).to eq 1
    mail_admin = mailer_q.first
    expect(mail_admin.subject).to match "DESTROY request! - #{user.full_name}"
    expect(mail_admin.to).to eq(ENV['MAILER_ADMIN_RECIPIENTS'].delete(' ').split(","))
  end
  
  it "should perform destroy" do
    action_double(DestroyAllServersConfirmed)
    user.update_attribute(:notif_delivered, user.notif_before_destroy)
    user.update_attribute(:admin_destroy_request, r_sent_conf)
    
    scope.check_user(user)
    
    expect(user.notif_delivered).to eq 0
    expect(mailer_q.count).to eq 2
    mail_user = mailer_q.first
    mail_admin = mailer_q.second
    expect(mail_user.subject).to match "servers destroyed"
    expect(mail_user.to).to eq [user.email]
    expect(mail_admin.subject).to match "Automatic destroy - #{user.full_name}"
    expect(mail_admin.to).to eq(ENV['MAILER_ADMIN_RECIPIENTS'].delete(' ').split(","))
  end
  
  it "should clear notifications after payment" do
    user.update_attribute(:notif_delivered, user.notif_before_destroy)
    user.update_attribute(:admin_destroy_request, r_sent_conf)
    FactoryGirl.create :charge, invoice: invoice, amount: 134_000
    expect(DestroyAllServersConfirmed).not_to receive(:new)
    scope.check_user(user)
    
    expect(user.notif_delivered).to eq 0
    expect(mailer_q.count).to eq 0
    expect(user.admin_destroy_request).to eq r_not_sent
  end
  
  it "should clear notifications after servers destroyed" do
    user.update_attribute(:notif_delivered, user.notif_before_destroy)
    user.update_attribute(:admin_destroy_request, r_sent_conf)
    user.servers.destroy_all
    
    expect(DestroyAllServersConfirmed).not_to receive(:new)
    scope.check_user(user)
    
    expect(user.notif_delivered).to eq 0
    expect(mailer_q.count).to eq 0
    expect(user.admin_destroy_request).to eq r_not_sent
  end
end
